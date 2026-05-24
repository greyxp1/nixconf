{ inputs, ... }:
{
  flake.nixosModules.nixcord =
    { ... }:
    {
      home-manager.sharedModules = [ inputs.nixcord.homeModules.nixcord ];
      home-manager.users.grey =
        { ... }:
        {
          programs.nixcord = {
            enable = true;
            discord = {
              enable = true;
              vencord.enable = false;
              equicord.enable = true;

              settings = {
                MINIMIZE_TO_TRAY = false;
                openasar = {
                  setup = true;
                  quickstart = true;
                  css = ''
                    @import url("https://refact0r.github.io/midnight-discord/build/midnight.css");
                    @import url(https://mwittrien.github.io/BetterDiscordAddons/Themes/EmojiReplace/base/Apple.css);
                    body {
                      --background-image: on;
                      --background-image-url: url('https://i.imgur.com/mOR0PoA.jpeg');
                      --top-bar-height: var(--gap);
                      --transparency-tweaks: on;
                      --panel-blur: on;
                      --blur-amount: 12px;
                      --bg-floating: hsla(220, 15%, 13%, 0.6);
                      --custom-chatbar: separated;
                      --small-user-panel: off;
                    }
                    :root { --bg-4: hsla(220, 15%, 10%, 0.81); }
                    div[class^="winButtons_"] { display: none !important; }
                    [class^="base_"] { --top-bar-right-margin: calc(32px * var(--button-count) + var(--button-count) * var(--space-xs)) !important; }
                  '';
                };
              };
            };

            userPlugins = {
              FakeDeafen = ./plugins/FakeDeafen;
              BetterAudioDefaults = ./plugins/BetterAudioDefaults;
            };

            extraConfig.plugins = {
              BetterAudioDefaults.enable = true;
              FakeDeafen.enable = true;
            };

            config = {
              plugins = {
                alwaysTrust.enable = true;
                betterCommands.enable = true;
                betterSettings.enable = true;
                betterUploadButton.enable = true;
                blockKrisp.enable = true;
                ClearURLs.enable = true;
                consoleJanitor.enable = true;
                copyFileContents.enable = true;
                copyStickerLinks.enable = true;
                crashHandler.enable = true;
                disableCallIdle.enable = true;
                expressionCloner.enable = true;
                fakeNitro.enable = true;
                fixCodeblockGap.enable = true;
                fixFileExtensions.enable = true;
                fixImagesQuality.enable = true;
                fixYoutubeEmbeds.enable = true;
                fullSearchContext.enable = true;
                FullVCPFP.enable = true;
                gifPaste.enable = true;
                guildPickerDumper.enable = true;
                hideMessages.enable = true;
                homeTyping.enable = true;
                keepCurrentChannel.enable = true;
                memberCount.enable = true;
                messageClickActions.enable = true;
                micLoopbackTester.enable = true;
                moreUserTags.enable = true;
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
                OnePingPerDM.enable = true;
                pinIcon.enable = true;
                platformIndicators.enable = true;
                previewMessage.enable = true;
                reactErrorDecoder.enable = true;
                relationshipNotifier.enable = true;
                remixRevived.enable = true;
                reverseImageSearch.enable = true;
                roleColorEverywhere.enable = true;
                searchFix.enable = true;
                showAllMessageButtons.enable = true;
                sendTimestamps.enable = true;
                showTimeoutDuration.enable = true;
                stickerPaste.enable = true;
                translate.enable = true;
                unindent.enable = true;
                userVoiceShow.enable = true;
                voiceChannelLog.enable = true;
                whoReacted.enable = true;
                whosWatching.enable = true;
                youtubeAdblock.enable = true;
                zipPreview.enable = true;

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

                messageLoggerEnhanced = {
                  enable = true;
                  attachmentSizeLimitInMegabytes = 500;
                  cacheMessagesFromServers = true;
                  ignoreSelf = true;
                  messageLimit = 0;
                  saveImages = true;
                };

                voiceRejoin = {
                  enable = true;
                  preventReconnectIfCallEnded = "none";
                  rejoinDelay = 1.0;
                  rejoinTimeout = 120.0;
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

                declutter = {
                  enable = true;
                  removeShopAboveDM = true;
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
    };
}
