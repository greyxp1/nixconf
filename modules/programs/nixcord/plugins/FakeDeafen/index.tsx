// @ts-nocheck
import {
  addContextMenuPatch,
  findGroupChildrenByChildId,
  NavContextMenuPatchCallback,
  removeContextMenuPatch,
} from "@api/ContextMenu";
import { definePluginSettings } from "@api/Settings";
import definePlugin, { OptionType } from "@utils/types";
import { findByProps } from "@webpack";
import { Menu, React, UserStore } from "@webpack/common";

const settings = definePluginSettings({
  enabled: {
    type: OptionType.BOOLEAN,
    description: "Fake Deafen Status",
    default: false,
    restartRequired: false,
  },
});

let socket: any, originalSend: any;
let ChannelStore: any, SelectedChannelStore: any, MediaEngineStore: any;
function refreshVoiceState(enabled: boolean) {
  const channelId = SelectedChannelStore?.getVoiceChannelId();
  if (!socket || !channelId) return;
  try {
    socket.send(4, {
      guild_id: ChannelStore?.getChannel(channelId)?.guild_id ?? null,
      channel_id: channelId,
      self_mute: enabled || (MediaEngineStore?.isMute() ?? false),
      self_deaf: enabled || (MediaEngineStore?.isDeaf() ?? false),
    });
  } catch (e) {
    console.error("[FakeDeafen] Failed to refresh voice state", e);
  }
}

const userContextPatch: NavContextMenuPatchCallback = (children, { user }) => {
  if (user?.id !== UserStore.getCurrentUser()?.id) return;
  const item = (
    <Menu.MenuCheckboxItem
      id="fake-deafen-toggle"
      label="Fake Deafen"
      checked={settings.store.enabled}
      action={() => {
        const next = !settings.store.enabled;
        settings.store.enabled = next;
        refreshVoiceState(next);
      }}
    />
  );

  const group =
    findGroupChildrenByChildId("mute", children) ??
    findGroupChildrenByChildId("deafen", children);
  if (group) group.push(item);
  else children.push(<Menu.MenuGroup>{item}</Menu.MenuGroup>);
};

export default definePlugin({
  name: "FakeDeafen",
  description: "Fake deafen yourself using native framework APIs",
  authors: [{ name: "greyxp1", id: 1233920168196046892n }],
  settings,

  start() {
    settings.store.enabled = false;
    ChannelStore = findByProps("getChannel", "getDMFromUserId");
    SelectedChannelStore = findByProps("getVoiceChannelId");
    MediaEngineStore = findByProps("isDeaf", "isMute");
    socket = findByProps("getSocket")?.getSocket();
    if (!socket) return;
    originalSend = socket.send;
    socket.send = function (op: number, data: any, ...args: any[]) {
      if (op === 4 && settings.store.enabled && data) {
        data.self_mute = true;
        data.self_deaf = true;
      }
      return originalSend.apply(this, [op, data, ...args]);
    };
    addContextMenuPatch("user-context", userContextPatch);
  },

  stop() {
    if (socket && originalSend) socket.send = originalSend;
    removeContextMenuPatch("user-context", userContextPatch);
  },
});
