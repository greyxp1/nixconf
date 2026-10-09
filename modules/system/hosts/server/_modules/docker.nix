{...}: {
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  preservation.preserveAt."/persistent".directories = ["/var/lib/docker"];
}
