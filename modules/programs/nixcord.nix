{inputs, ...}: let
  cordStashPath = subpath:
    /. + builtins.unsafeDiscardStringContext "${inputs.cord-stash}/${subpath}";
in {
  flake.homeModules.nixcord = {
    imports = [inputs.nixcord.homeModules.nixcord];

    programs.nixcord = {
      enable = true;
      useGlobalPkgs = true;
      quickCss = builtins.readFile (cordStashPath "themes/catppuccin-mocha.css");

      discord = {
        equicord.enable = true;
        settings = {
          MINIMIZE_TO_TRAY = false;
          openasar = {
            setup = true;
            quickstart = true;
            noTyping = true;
          };
        };

        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder"
          "--enable-blink-features=MiddleClickAutoscroll"
          "--ozone-platform-hint=auto"
        ];
      };

      userPlugins = {
        autoReact = cordStashPath "plugins/AutoReact";
        betterAudioDefaults = cordStashPath "plugins/BetterAudioDefaults";
        fakeDeafen = cordStashPath "plugins/FakeDeafen";
        localEdit = cordStashPath "plugins/LocalEdit";
      };

      extraConfig = {
        plugins = {
          autoReact.enable = true;
          betterAudioDefaults.enable = true;
          fakeDeafen.enable = true;
          localEdit.enable = true;
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
          sendTimestamps.enable = true;
          showAllMessageButtons.enable = true;
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
          whosWatching.enable = true;
          youtubeAdblock.enable = true;

          callTimer = {
            enable = true;
            format = "human";
          };

          declutter = {
            enable = true;
            removeAvatarDecoration = true;
            removeShopAboveDms = true;
          };

          equibopStreamFixes = {
            enable = true;
            bitsPerPixelPct = 16;
            minBitrate = 6000;
          };

          followVoiceUser = {
            enable = true;
            onlyWhenInVoice = false;
          };

          imageZoom = {
            enable = true;
            size = 500.0;
            square = true;
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

          newGuildSettings = {
            enable = true;
            messages = 1;
          };

          questify = {
            enable = true;
            acknowledgedNotices = {
              quest-ban-warning-2026-08-07 = true;
              quest-ban-warning-2026-08-26 = true;
            };
            allowChangingDangerousSettings = true;
            autoCompleteQuestTypes = {
              PLAY_ON_DESKTOP = true;
              PLAY_ON_XBOX = true;
              PLAY_ON_PLAYSTATION = true;
              PLAY_ACTIVITY = true;
              WATCH_VIDEO = true;
              WATCH_VIDEO_ON_MOBILE = true;
              ACHIEVEMENT_IN_ACTIVITY = true;
            };
            autoCompleteQuestsSimultaneously = true;
            completeVideoQuestsQuicker = true;
            preventVideoQuestsPausing = true;
            disableAccountPanelQuestProgress = true;
            disableOrbsAndQuestsBadges = true;
            disableSponsoredBanner = true;
            makeMobileVideoQuestsDesktopCompatible = true;
            questButtonDisplay = "unclaimed";
            resumeInterruptedQuests = true;
          };

          quoter = {
            enable = true;
            watermark = "Made by greyxp1";
          };

          viewIcons = {
            enable = true;
            format = "png";
            imgSize = "4096";
          };

          voiceMessages = {
            enable = true;
            echoCancellation = false;
            noiseSuppression = false;
          };

          voiceRejoin = {
            enable = true;
            preventReconnectIfCallEnded = "none";
            rejoinDelay = 1.0;
            rejoinTimeout = 120.0;
          };
        };
      };
    };
  };
}
