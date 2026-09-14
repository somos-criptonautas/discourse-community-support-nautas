import Component from "@glimmer/component";
import { action } from "@ember/object";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import { i18n } from "discourse-i18n";
import DonateContent from "../donate-content";

export default class DonateModal extends Component {
  get sizeClass() {
    if (settings.modal_size === "large") {
      return "--large";
    }
    if (settings.modal_size === "maximized") {
      return "--max";
    }
    return "";
  }

  get design() {
    return settings.design || "classic";
  }

  @action
  close() {
    this.args.model?.onClose?.();
    this.args.closeModal();
  }

  <template>
    <DButton
      @action={{this.close}}
      @icon="xmark"
      @translatedTitle={{i18n "js.modal.close"}}
      class="donate-modal__close"
    />
    <DModal
      @title={{i18n (themePrefix "main_heading_content.title")}}
      @closeModal={{this.close}}
      @hideHeader={{true}}
      @hideFooter={{true}}
      @autofocus={{false}}
      class="donate-modal {{this.sizeClass}} --design-{{this.design}}"
    >
      <:body>
        <DonateContent
          @view="full"
          @design={{this.design}}
          @showSupportBar={{settings.support_bar_in_modal}}
          @onClose={{this.close}}
        />
      </:body>
    </DModal>
  </template>
}
