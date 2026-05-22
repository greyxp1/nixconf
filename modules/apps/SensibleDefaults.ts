import definePlugin from "@utils/types";
import { findByProps } from "@webpack";

export default definePlugin({
  name: "SensibleDefaults",
  description:
    "Enforces sensible defaults on startup: activates Studio Profile and QoS, while disabling voice channel switching modals, silence warnings, attenuation, and debug logging.",
  authors: [{ name: "greyxp1", id: 0n }],
  tags: ["Voice", "Utility"],
  restartNeeded: true,

  _origHandleVoiceConnect: null,

  start() {
    const mx = findByProps("setInputVolume", "setOutputVolume");
    if (mx) {
      mx.setActiveInputProfile("STUDIO");
      mx.setSilenceWarning(false);
      mx.setQoS(true);
      mx.setSidechainCompression(false);
      mx.setSidechainCompressionStrength(0);
      mx.setDebugLogging(false);
    }

    const vcModule = findByProps("handleVoiceConnect");
    if (vcModule && vcModule.handleVoiceConnect) {
      this._origHandleVoiceConnect = vcModule.handleVoiceConnect;
      const originalFn = this._origHandleVoiceConnect;

      vcModule.handleVoiceConnect = function (e) {
        return originalFn.call(this, {
          ...e,
          bypassChangeModal: true,
        });
      };
    }
  },

  stop() {
    const vcModule = findByProps("handleVoiceConnect");
    if (vcModule && this._origHandleVoiceConnect) {
      vcModule.handleVoiceConnect = this._origHandleVoiceConnect;
      this._origHandleVoiceConnect = null;
    }
  },
});
