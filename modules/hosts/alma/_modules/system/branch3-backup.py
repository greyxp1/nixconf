#!/usr/bin/python3
"""Back up the four local VMs to the classroom USB disk."""
import datetime, fcntl, hashlib, json, os, pathlib, shlex, shutil
import signal, subprocess, time, xml.etree.ElementTree as ET

os.umask(0o077)
BASE = pathlib.Path('/home/libvirt/backups')
REMOTE = '/mnt/pve/BackUp/virt-manager-backups'
SSH = ['ssh', '-i', '/etc/branch3-backup/id_ed25519', '-o', 'IdentitiesOnly=yes',
       '-o', 'BatchMode=yes', '-o', 'ConnectTimeout=10', '-o', 'StrictHostKeyChecking=yes',
       '-o', 'UserKnownHostsFile=/etc/branch3-backup/known_hosts',
       '-o', 'ServerAliveInterval=30', '-o', 'ServerAliveCountMax=3']
UUID = '5abe142f-dd57-4764-81b0-9b72edb4e484'
MOUNT = '/mnt/pve/BackUp'

def run(args, **kwargs):
    return subprocess.run(args, check=True, text=True, timeout=5400, **kwargs)

def remote(command, **kwargs):
    guard = 'test "$(findmnt -n -o UUID -M ' + MOUNT + ')" = ' + UUID
    return run(SSH + [guard + ' && ' + command], **kwargs)

def interrupted(signum, frame):
    raise RuntimeError('Backup interrupted; incomplete copies are not published')

def select_host():
    for address in ('10.64.100.109', '10.64.100.110'):
        try:
            probe = subprocess.run(SSH + ['root@' + address,
                'findmnt -n -o UUID -M ' + MOUNT], text=True,
                capture_output=True, timeout=20)
        except subprocess.TimeoutExpired:
            print('Backup host timed out: ' + address, flush=True)
            continue
        if probe.returncode == 0 and probe.stdout.strip() == UUID:
            SSH.append('root@' + address)
            print('Backup disk found on ' + address, flush=True)
            return True
    print('Backup disk is absent. Will try again later', flush=True)
    return False


def main():
    for sig in (signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, interrupted)
    with open('/run/branch3-backup.lock', 'w') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        if not select_host():
            return
        today = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%d')
        result = run(SSH + ['cat ' + REMOTE + '/last-success-date 2>/dev/null || true'],
                     capture_output=True)
        if result.stdout.strip() == today:
            print('Branch 3 backup already verified today', flush=True)
            return
        complete = sorted(p for p in BASE.glob('scheduled-' + today + 'T*Z')
                          if (p / 'SHA256SUMS').is_file() and
                          json.loads((p / 'restore-map.json').read_text()).get('backup_format') == 2)
        if complete:
            stage = complete[-1]
            stamp = stage.name.removeprefix('scheduled-')
            run(['sha256sum', '-c', 'SHA256SUMS'], cwd=stage)
        else:
            stage, stamp = build_stage()
        transfer(stage, stamp, today)


def build_stage():
    import libvirt
    if shutil.disk_usage(BASE).free < 60 * 1024**3:
        raise RuntimeError('Need 60 GiB free locally before starting a full backup')
    stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    stage = BASE / ('scheduled-' + stamp)
    stage.mkdir(mode=0o711)
    os.chmod(stage, 0o711)
    conn = libvirt.open('qemu:///system')
    manifest = {'backup_format': 2, 'date_utc': stamp, 'guests': {}, 'consistency': 'VM crash-consistent'}
    for name in ('pfSense', 'AD-Server', 'HQ-Server', 'Linux-Client'):
        guest = conn.lookupByName(name)
        xml = guest.XMLDesc(libvirt.VIR_DOMAIN_XML_INACTIVE)
        (stage / (name + '.xml')).write_text(xml)
        backup = ET.Element('domainbackup', mode='push')
        disks = ET.SubElement(backup, 'disks')
        images = []
        mapping = {}
        for disk in ET.fromstring(xml).findall('./devices/disk'):
            target = disk.find('target').get('dev')
            source = disk.find('source')
            if disk.get('device') != 'disk':
                ET.SubElement(disks, 'disk', name=target, backup='no')
                if source is not None and source.get('file'):
                    seed = stage / (name + '-' + target + '.iso')
                    shutil.copyfile(source.get('file'), seed)
                    mapping[seed.name] = source.get('file')
                continue
            if disk.get('type') != 'file' or source is None:
                raise RuntimeError('Unsupported disk type; refusing partial backup')
            image = stage / (name + '-' + target + '.qcow2')
            images.append((image, source.get('file')))
            mapping[image.name] = source.get('file')
            element = ET.SubElement(disks, 'disk', name=target, backup='yes', type='file')
            ET.SubElement(element, 'driver', type='qcow2')
            ET.SubElement(element, 'target', file=str(image))
        if guest.isActive():
            started = False
            try:
                guest.backupBegin(ET.tostring(backup, encoding='unicode'), None)
                started = True
                deadline = time.monotonic() + 1800
                while guest.jobStats().get('type', 0) != libvirt.VIR_DOMAIN_JOB_NONE:
                    if time.monotonic() > deadline:
                        raise RuntimeError('VM backup exceeded 30 minutes')
                    time.sleep(2)
                stats = guest.jobStats(libvirt.VIR_DOMAIN_JOB_STATS_COMPLETED)
                if stats.get('type') != libvirt.VIR_DOMAIN_JOB_COMPLETED:
                    raise RuntimeError('VM backup did not finish successfully: ' + str(stats))
                started = False
            finally:
                if started:
                    guest.abortJob()
        else:
            for image, source in images:
                run(['qemu-img', 'convert', '-O', 'qcow2', source, str(image)])
        for image, source in images:
            run(['qemu-img', 'check', str(image)])
        manifest['guests'][name] = mapping
        print('Saved ' + name, flush=True)
    conn.close()
    (stage / 'restore-map.json').write_text(json.dumps(manifest, indent=2) + '\n')
    os.chmod(stage, 0o700)
    hashes = []
    for path in sorted(stage.iterdir()):
        h = hashlib.sha256()
        with path.open('rb') as file:
            for block in iter(lambda: file.read(8 * 1024**2), b''):
                h.update(block)
        hashes.append(h.hexdigest() + '  ' + path.name)
    (stage / 'SHA256SUMS').write_text('\n'.join(hashes) + '\n')
    return stage, stamp


def transfer(stage, stamp, today):
    holder = subprocess.Popen(SSH + [
        'flock -x -w 10800 ' + MOUNT + '/.b2b-write.lock '
        + "sh -c 'echo LOCKED; cat >/dev/null'"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
    try:
        if holder.stdout.readline().strip() != 'LOCKED':
            raise RuntimeError('Could not acquire the USB backup lock')
        remote('mkdir -p ' + REMOTE)
        pending = REMOTE + '/.incoming-' + stamp
        final = REMOTE + '/scheduled-' + stamp
        existing = remote('if test -d ' + shlex.quote(final) +
                          '; then echo present; fi', capture_output=True)
        if existing.stdout.strip() == 'present':
            remote('cd ' + shlex.quote(final) + ' && sha256sum -c SHA256SUMS')
        else:
            remote('mkdir -p -m 700 ' + shlex.quote(pending))
            run(['rsync', '-a', '--bwlimit=61440', '-e', shlex.join(SSH[:-1]), str(stage) + '/',
                 SSH[-1] + ':' + pending + '/'])
            remote('cd ' + shlex.quote(pending) +
                   ' && sha256sum -c SHA256SUMS && test ! -e ' + shlex.quote(final) +
                   ' && mv ' + shlex.quote(pending) + ' ' + shlex.quote(final))
        # Restrict retention to this job's verified timestamped directories only.
        prune = '''import pathlib,re,shutil
base=pathlib.Path('/mnt/pve/BackUp/virt-manager-backups')
dirs=sorted((p for p in base.iterdir() if re.fullmatch(r'scheduled-[0-9]{8}T[0-9]{6}Z',p.name) and not p.is_symlink() and p.is_dir() and (p/'SHA256SUMS').is_file()),reverse=True)
keep=set(dirs[:3]); days=set()
for p in dirs:
 day=p.name[10:18]
 if day not in days and len(days)<3:
  days.add(day); keep.add(p)
for p in dirs:
 if p not in keep:
  shutil.rmtree(p); print('Expired backup: '+p.name)
'''
        remote('python3 -c ' + shlex.quote(prune))
        remote('sync -f ' + MOUNT + ' && printf %s ' + today + ' > ' + REMOTE +
               '/.last-success-date.tmp && mv ' + REMOTE + '/.last-success-date.tmp ' +
               REMOTE + '/last-success-date && sync -f ' + MOUNT)
        # This exact directory was created by this invocation; verified copy exists on USB.
        shutil.rmtree(stage)
        print('SUCCESS: ' + final, flush=True)
    finally:
        holder.stdin.close()
        holder.wait(timeout=30)

if __name__ == '__main__':
    main()
