{inputs, ...}: {
  imports = [inputs.nixcord.nixosModules.nixcord];
  programs.nixcord = {
    enable = true;
    user = "grey";
    useGlobalPkgs = true;
    discord.enable = false;
    quickCss = "@import url(https://mwittrien.github.io/BetterDiscordAddons/Themes/EmojiReplace/base/Apple.css);";
    userPlugins = {
      autoReact = "${inputs.cord-stash}/plugins/AutoReact";
      clientPreferences = "${inputs.cord-stash}/plugins/ClientPreferences";
      discordPopoutTitle = "${inputs.cord-stash}/plugins/DiscordPopoutTitle";
      fakeDeafen = "${inputs.cord-stash}/plugins/FakeDeafen";
      localEdit = "${inputs.cord-stash}/plugins/LocalEdit";
    };

    browser = {
      enable = true;
      client = "equicord";
      extraConfig = {
        useQuickCSS = true;
        plugins = {
          Questify = {
            enabled = true;
            migrationVersion = 1;
            disableQuestsEverything = true;
          };
          AutoReact.enabled = true;
          LocalEdit.enabled = true;
          AddAttachments.enabled = true;
          AlwaysTrust.enabled = true;
          BetterCommands.enabled = true;
          BetterSettings.enabled = true;
          BetterUploadButton.enabled = true;
          ClearURLs.enabled = true;
          CopyFileContents.enabled = true;
          CopyStickerLinks.enabled = true;
          DragFavoriteEmotes.enabled = true;
          ExpressionManager.enabled = true;
          FixCodeblockGap.enabled = true;
          FixFileExtensions.enabled = true;
          FixYoutubeEmbeds.enabled = true;
          GifPaste.enabled = true;
          GuildPickerDumper.enabled = true;
          HideMessages.enabled = true;
          HomeTyping.enabled = true;
          ImageZoom = {
            enabled = true;
            size = 500.0;
            square = true;
          };
          KeepCurrentChannel.enabled = true;
          MemberCount.enabled = true;
          MessageClickActions.enabled = true;
          MessageLogger = {
            enabled = true;
            collapseDeleted = true;
            ignoreSelf = true;
            inlineEdits = false;
            logEdits = false;
          };
          MoreUserTags = {
            enabled = true;
            dontShowBotTag = true;
            noAppsAllowed = true;
            tagSettings.VOICE_MODERATOR = {
              showInChat = false;
              showInNotChat = true;
            };
          };
          NewGuildSettings = {
            enabled = true;
            messages = 1;
          };
          NewPluginsManager.enabled = true;
          NoDevtoolsWarning.enabled = true;
          NoF1.enabled = true;
          NoMiddleClickPaste.enabled = true;
          NoNitroUpsell.enabled = true;
          NoOnboardingDelay.enabled = true;
          NoUnblockToJump.enabled = true;
          OnePingPerDM.enabled = true;
          PinIcon.enabled = true;
          PlatformIndicators.enabled = true;
          PreviewMessage.enabled = true;
          Quoter = {
            enabled = true;
            watermark = "Made by greyxp1";
          };
          ReactErrorDecoder.enabled = true;
          RelationshipNotifier.enabled = true;
          ReverseImageSearch.enabled = true;
          SearchFix.enabled = true;
          SendTimestamps.enabled = true;
          ShowAllMessageButtons.enabled = true;
          ShowTimeoutDuration.enabled = true;
          SilentTyping.enabled = true;
          StickerPaste.enabled = true;
          Translate.enabled = true;
          Unindent.enabled = true;
          ViewIcons = {
            enabled = true;
            format = "png";
            imgSize = "4096";
          };
          VoiceMessages = {
            enabled = true;
            echoCancellation = false;
            noiseSuppression = false;
          };
          WebContextMenus.enabled = true;
          WebKeybinds.enabled = true;
          WebScreenShareFixes.enabled = true;
          WhoReacted.enabled = true;
          YoutubeAdblock.enabled = true;

          # Voice chat and screensharing
          ClientPreferences = {
            enabled = true;
            inputProfile = "STUDIO";
            qos = true;
            silenceWarning = false;
            sidechainCompression = false;
            attenuation = 0;
            attenuateWhileSpeakingSelf = false;
            attenuateWhileSpeakingOthers = false;
            channelSwitchWarning = false;
          };
          DiscordPopoutTitle.enabled = true;
          FakeDeafen.enabled = true;
          BlockKrisp.enabled = true;
          CallTimer = {
            enabled = true;
            format = "human";
          };
          DisableCallIdle.enabled = true;
          FakeNitro.enabled = true;
          FollowVoiceUser = {
            enabled = true;
            onlyWhenInVoice = false;
          };
          FullVCPFP.enabled = true;
          NoPushToTalk.enabled = true;
          UserVoiceShow.enabled = true;
          VoiceChannelLog.enabled = true;
          VoiceRejoin = {
            enabled = true;
            preventReconnectIfCallEnded = "none";
            rejoinDelay = 1.0;
            rejoinTimeout = 120.0;
          };
          WhosWatching.enabled = true;

          # Performance and stability
          Declutter = {
            enabled = true;
            alwaysShowUsername = true;
            removeAudioMenus = true;
            removeAvatarDecoration = true;
            removeBillingSettings = true;
            removeButtonTooltips = true;
            removeClanTag = true;
            removeDisplayNameStyles = true;
            removeFamilyCenterAboveDms = true;
            removeGiftButton = true;
            removeLibraryAboveDms = true;
            removeNameplate = true;
            removeProfileEffect = true;
            removeProfileFrame = true;
            removeQuestsAboveDms = false;
            removeServerBoostInfo = true;
            removeShopAboveDms = true;
            removeUnavailableEmojiPicker = true;
          };
          ConsoleJanitor = {
            enabled = true;
            disableLoggers = true;
          };
          CrashHandler.enabled = true;
          NoTypingAnimation.enabled = true;
        };
      };
    };
  };
}
