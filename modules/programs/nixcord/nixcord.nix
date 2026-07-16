{inputs, ...}: {
  flake.homeModules.nixcord = {
    imports = [inputs.nixcord.homeModules.nixcord];
    programs.nixcord = {
      enable = true;
      quickCss = ''
        div[class^="winButtons_"] {display: none !important;}

        .visual-refresh.theme-dark,
        .visual-refresh .theme-dark {
          --brand-500: #89b4fa;
          --brand-530: #71a4f9;
          --brand-560: #5895f8;
          --text-default: #cdd6f4;
          --text-muted: #a6adc8;
          --text-link: #89b4fa;
          --text-strong: #cdd6f4;
          --text-subtle: #bac2de;
          --channels-default: #969ebe;
          --channel-icon: #969ebe;
          --interactive-icon-default: #cdd6f4;
          --interactive-text-default: #cdd6f4;
          --interactive-muted: #6c7086;
          --interactive-background-hover: rgba(147, 153, 178, 0.15);
          --interactive-background-selected: rgba(108, 112, 134, 0.2);
          --interactive-background-active: rgba(205, 214, 244, 0.17);
          --background-base-lowest: #11111b;
          --background-base-lower: #181825;
          --background-base-low: #1c1c2b;
          --background-surface-high: #1e1e2e;
          --background-surface-higher: #2b2b3b;
          --background-surface-highest: #313244;
          --background-secondary-alt: #1c1c2b;
          --background-mod-muted: rgba(88, 91, 112, 0.05);
          --background-mod-normal: rgba(88, 91, 112, 0.15);
          --background-mod-subtle: rgba(88, 91, 112, 0.25);
          --background-mod-strong: rgba(88, 91, 112, 0.45);
          --home-background: #1e1e2e;
          --chat-background: #1e1e2e;
          --chat-background-default: #1e1e2e;
          --chat-border: #11111b;
          --custom-channel-members-bg: #181825;
          --channeltextarea-background: #181825;
          --modal-background: #1e1e2e;
          --modal-footer-background: #1e1e2e;
          --input-background-default: #11111b;
          --card-background-default: #313244;
          --border-muted: #313244;
          --border-strong: #181825;
          --border-normal: #11111b;
          --border-subtle: #1e1e2e;
          --mention-foreground: #89b4fa;
          --mention-background: rgba(137, 180, 250, 0.3);
          --message-mentioned-background-default: rgba(249, 226, 175, 0.1);
          --message-mentioned-background-hover: rgba(249, 226, 175, 0.08);
          --message-background-hover: rgba(17, 17, 27, 0.3);
          --status-positive: #a6e3a1;
          --status-warning: #f9e2af;
          --status-danger: #f38ba8;
          --badge-notification-background: #f38ba8;
          --scrollbar-thin-thumb: #89b4fa;
          --scrollbar-thin-track: transparent;
          --scrollbar-auto-thumb: #89b4fa;
          --scrollbar-auto-track: #11111b;
        }
      '';

      discord = {
        enable = true;
        equicord.enable = true;
        settings = {
          SKIP_HOST_UPDATE = true;
          SKIP_MODULE_UPDATE = true;
          USE_NEW_UPDATER = false;
          MINIMIZE_TO_TRAY = false;
          openasar = {
            setup = true;
            quickstart = true;
          };
        };

        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder"
          "--enable-blink-features=MiddleClickAutoscroll"
          "--ozone-platform-hint=auto"
        ];
      };

      userPlugins = {
        FakeDeafen = ./plugins/FakeDeafen;
        BetterAudioDefaults = ./plugins/BetterAudioDefaults;
      };

      extraConfig = {
        enableOnlineThemes = false;
        plugins = {
          BetterAudioDefaults.enable = true;
          FakeDeafen.enable = true;
        };
      };

      config = {
        useQuickCss = true;
        plugins = {
          alwaysTrust.enable = true;
          betterCommands.enable = true;
          betterUploadButton.enable = true;
          blockKrisp.enable = true;
          clearUrls.enable = true;
          consoleJanitor.enable = true;
          copyFileContents.enable = true;
          copyStickerLinks.enable = true;
          crashHandler.enable = true;
          disableCallIdle.enable = true;
          expressionCloner.enable = true;
          fakeNitro.enable = true;
          fixCodeblockGap.enable = true;
          fixFileExtensions.enable = true;
          fixYoutubeEmbeds.enable = true;
          fullVcpfp.enable = true;
          gifPaste.enable = true;
          guildPickerDumper.enable = true;
          hideMessages.enable = true;
          homeTyping.enable = true;
          keepCurrentChannel.enable = true;
          memberCount.enable = true;
          messageClickActions.enable = true;
          newPluginsManager.enable = true;
          noDevtoolsWarning.enable = true;
          noF1.enable = true;
          noMiddleClickPaste.enable = true;
          noMosaic.enable = true;
          noNitroUpsell.enable = true;
          noOnboardingDelay.enable = true;
          noPushToTalk.enable = true;
          noTypingAnimation.enable = true;
          noUnblockToJump.enable = true;
          onePingPerDm.enable = true;
          pinIcon.enable = true;
          platformIndicators.enable = true;
          previewMessage.enable = true;
          reactErrorDecoder.enable = true;
          relationshipNotifier.enable = true;
          remixRevived.enable = true;
          reverseImageSearch.enable = true;
          searchFix.enable = true;
          showAllMessageButtons.enable = true;
          sendTimestamps.enable = true;
          showTimeoutDuration.enable = true;
          stickerPaste.enable = true;
          translate.enable = true;
          unindent.enable = true;
          userVoiceShow.enable = true;
          voiceChannelLog.enable = true;
          webContextMenus.enable = true;
          webKeybinds.enable = true;
          webScreenShareFixes.enable = true;
          whoReacted.enable = true;
          youtubeAdblock.enable = true;

          questify = {
            enable = true;
            allowChangingDangerousSettings = true;
            autoCompleteQuestsSimultaneously = true;
            completeVideoQuestsQuicker = true;
            disableAccountPanelPromo = true;
            disableAccountPanelQuestProgress = true;
            disableFriendsListPromo = true;
            disableMembersListPromo = true;
            disableOrbsAndQuestsBadges = true;
            disableSponsoredBanner = true;
            makeMobileVideoQuestsDesktopCompatible = true;
            questButtonDisplay = "unclaimed";
            resumeInterruptedQuests = true;
            autoCompleteQuestTypes = {
              PLAY_ON_DESKTOP = true;
              PLAY_ON_XBOX = true;
              PLAY_ON_PLAYSTATION = true;
              PLAY_ACTIVITY = true;
              WATCH_VIDEO = true;
              WATCH_VIDEO_ON_MOBILE = true;
              ACHIEVEMENT_IN_ACTIVITY = true;
            };
          };

          declutter = {
            enable = true;
            removeAvatarDecoration = true;
            removeNameplate = true;
            removeProfileEffect = true;
            removeClanTag = true;
            removeShopAboveDms = true;
            removeQuestsAboveDms = true;
            removeServerBoostInfo = true;
            removeBillingSettings = true;
            removeGiftButton = true;
            removeUnavailableEmojiPicker = true;
          };

          messageLogger = {
            enable = true;
            collapseDeleted = true;
            ignoreBots = true;
            ignoreSelf = true;
            inlineEdits = false;
            logEdits = false;
          };

          moreUserTags = {
            enable = true;
            dontShowBotTag = true;
            noAppsAllowed = true;
            tagSettings.voiceModerator.showInChat = false;
          };

          voiceRejoin = {
            enable = true;
            preventReconnectIfCallEnded = "none";
            rejoinDelay = 1.0;
            rejoinTimeout = 120.0;
          };

          equibopStreamFixes = {
            enable = true;
            minBitrate = 6000;
            bitsPerPixelPct = 16;
          };

          voiceMessages = {
            enable = true;
            echoCancellation = false;
            noiseSuppression = false;
          };

          imageZoom = {
            enable = true;
            square = true;
            size = 500.0;
          };

          viewIcons = {
            enable = true;
            format = "png";
            imgSize = "4096";
          };

          callTimer = {
            enable = true;
            format = "human";
          };

          followVoiceUser = {
            enable = true;
            onlyWhenInVoice = false;
          };

          newGuildSettings = {
            enable = true;
            messages = 1;
          };

          quoter = {
            enable = true;
            watermark = "Made by greyxp1";
          };
        };
      };
    };
  };
}
