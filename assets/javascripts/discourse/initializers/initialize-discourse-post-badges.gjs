import Component from "@ember/component";
import { service } from "@ember/service";
import { makeArray } from "discourse/lib/helpers";
import { withPluginApi } from "discourse/lib/plugin-api";
import PostUserFeaturedBadges from "../components/post-user-featured-badges";

const BADGE_CLASS = [
  "badge-type-gold",
  "badge-type-silver",
  "badge-type-bronze",
];

const TRUST_LEVEL_BADGE = ["basic", "member", "regular", "leader"];
const USER_BADGE_PAGE = "user's badge page";

function loadUserBadges({ allBadges, username, linkDestination }) {
  let badgePage = "";

  const isUserBadgePage = linkDestination === USER_BADGE_PAGE;
  if (isUserBadgePage) {
    badgePage = `?username=${username}`;
  }

  return makeArray(allBadges).map((badge) => {
    return {
      icon: badge.icon.replace("fa-", ""),
      image: badge.image_url ? badge.image_url : badge.image,
      className: BADGE_CLASS[badge.badge_type_id - 1],
      tlClassnames:
        badge.id >= 1 && badge.id <= 4 ? TRUST_LEVEL_BADGE[badge.id - 1] : "",
      name: badge.slug,
      id: badge.id,
      badgeGroup: badge.badge_grouping_id,
      title: badge.description.replace(/<\/?[^>]+(>|$)/g, ""),
      url: `/badges/${badge.id}/${badge.slug}${badgePage}`,
    };
  });
}

function highestTLClassname(badges) {
  if (!badges) {
    return "";
  }

  let trustLevel = "";
  let highestBadge = 0;

  badges.forEach((badge) => {
    if (badge.badgeGroup === 4 && badge.id > highestBadge) {
      highestBadge = badge.id;
      trustLevel = `${TRUST_LEVEL_BADGE[highestBadge - 1]}-highest`;
    }
  });

  return trustLevel || "";
}

export default {
  name: "discourse-post-badges-plugin",

  initialize(container) {
    withPluginApi((api) => {
      const siteSettings = container.lookup("service:site-settings");

      let containerClassname = ["poster-icon-container"];
      if (siteSettings.post_badges_only_show_highest_trust_level) {
        containerClassname.push("show-highest");
      }

      api.addTrackedPostProperties("user_badges");

      const component = class extends Component {
        @service siteSettings;
        @service site;

        get badges() {
          const { user_badges: allBadges, username } = this.outletArgs.post;
          const linkDestination =
            this.siteSettings.post_badges_badge_link_destination;

          return loadUserBadges({
            allBadges,
            username,
            linkDestination,
          });
        }

        get classnames() {
          return [...containerClassname, highestTLClassname(this.badges)]
            .filter(Boolean)
            .join(" ");
        }

        get shouldRenderBefore() {
          return this.site.mobileView;
        }

        <template>
          <div class={{this.classnames}}>
            <PostUserFeaturedBadges @badges={{this.badges}} @tagName="" />
          </div>
        </template>
      };

      // Register both outlets and let the component decide when to render
      api.renderBeforeWrapperOutlet(
        "post-meta-data-poster-name",
        class extends component {
          <template>
            {{#if this.shouldRenderBefore}}
              <div class={{this.classnames}}>
                <PostUserFeaturedBadges @badges={{this.badges}} @tagName="" />
              </div>
            {{/if}}
          </template>
        }
      );

      api.renderAfterWrapperOutlet(
        "post-meta-data-poster-name",
        class extends component {
          <template>
            {{#unless this.shouldRenderBefore}}
              <div class={{this.classnames}}>
                <PostUserFeaturedBadges @badges={{this.badges}} @tagName="" />
              </div>
            {{/unless}}
          </template>
        }
      );
    });
  },
};
