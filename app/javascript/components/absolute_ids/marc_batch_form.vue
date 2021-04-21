<template>
  <form
    :method="method"
    :action="action"
    class="absolute-ids-form"
    v-bind:value="value"
    v-on:input="onInput"
    v-on:submit.prevent="submit"
  >
    <grid-container>
      <grid-item columns="sm-12 lg-3">
        <fieldset class="absolute-ids-form--fields">
          <legend>Barcode</legend>

          <absolute-id-input-text
            id="barcode"
            v-bind:classes="barcodeInputClasses"
            name="barcode"
            label="Barcode"
            :hide-label="true"
            :helper="size > 1 ? 'Starting Barcode' : null"
            :maxlength="barcodeLength"
            v-on:input="onBarcodeInput($event)"
            :disabled="barcodeValid"
            :value="startingBarcode()"
          />

          <div class="lux-input">
            <div class="lux-input-status">
              {{ barcodeStatus }}
            </div>
          </div>

          <input-text
            v-if="size > 1"
            id="terminal_code"
            class="absolute-ids-form--input-field"
            name="terminal_code"
            label="Input"
            :hide-label="true"
            placeholder="Ending Barcode"
            helper="Ending Barcode"
            :disabled="true"
            :value="endingBarcode()"
          />

          <div class="lux-input">
            <button
              data-v-b7851b04
              class="lux-button solid"
              @click.prevent="clearBarcode()"
            >
              Reset
            </button>
          </div>
        </fieldset>
      </grid-item>

      <grid-item columns="sm-12 lg-9">
        <fieldset class="absolute-ids-form--fields">
          <div>
            MARC Records (<a href="https://catalog.princeton.edu"
              >Online Catalog</a
            >)
          </div>

          <grid-container>
            <grid-item columns="sm-12 lg-12">
              <input-text
                id="location_id"
                class="absolute-ids-form--input-field"
                name="location_id"
                label="Location"
                :hide-label="true"
                helper="Location"
                placeholder="Enter a location"
                v-model="selectedLocationId"
              />

              <input-text
                id="container_profile_id"
                class="absolute-ids-form--input-field"
                name="container_profile_id"
                label="Container Profile"
                :hide-label="true"
                helper="Size"
                placeholder="Enter a shelving size code"
                v-model="selectedContainerProfileId"
              />

              <input-text
                id="repository_id"
                class="absolute-ids-form--input-field"
                name="repository_id"
                label="Repository"
                :hide-label="true"
                helper="Repository"
                placeholder="Enter a repository"
                v-model="selectedRepositoryId"
                display-property="repoCode"
                v-on:input="changeRepositoryId($event)"
              />
            </grid-item>

            <grid-item columns="sm-12 lg-12">
              <input-text
                id="resource_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedResource,
                  'absolute-ids-form--input-field__invalid':
                    resourceTitle.length > 0 && !validResource,
                  'absolute-ids-form--input-field': true
                }"
                name="resource_id"
                label="Call Number"
                :hide-label="true"
                helper="Call Number"
                :placeholder="resourcePlaceholder"
                :disabled="!selectedRepositoryId || validatingResource"
                v-on:inputblur="onResourceFocusOut($event, resourceTitle)"
                v-model="resourceTitle"
              >
              </input-text>

              <div class="lux-input">
                <div class="lux-input-status">
                  {{ resourceStatus }}
                </div>
              </div>
            </grid-item>
            <grid-item columns="sm-12 lg-9">
              <div>
                <input-checkbox
                  :options="[
                    {
                      name: 'batch_mode',
                      label: 'Reference a range of box numbers',
                      value: batchMode,
                      id: 'checkbox-opt1',
                      checked: batchMode
                    }
                  ]"
                  v-on:change="onChangeBatchMode"
                />
              </div>
            </grid-item>
            <grid-item columns="sm-12 lg-9">
              <input-text
                id="container_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedContainer,
                  'absolute-ids-form--input-field__invalid':
                    containerIndicator.length > 0 && !validContainer,
                  'absolute-ids-form--input-field': true
                }"
                name="container_id"
                :label="batchMode ? 'Starting Box Number' : 'Box Number'"
                :hide-label="true"
                :helper="batchMode ? 'Starting Box Number' : 'Box Number'"
                :placeholder="containerPlaceholder"
                :disabled="
                  !selectedRepositoryId || !resourceTitle || validatingContainer
                "
                v-on:inputblur="onContainerFocusOut($event, containerIndicator)"
                v-model="containerIndicator"
              />

              <input-text
                v-if="batchMode"
                id="ending_container_id"
                class="absolute-ids-form--input-field"
                name="ending_container_id"
                label="Ending Box Number (Optional)"
                :hide-label="true"
                helper="Ending Box Number"
                :placeholder="endingContainerPlaceholder"
                :disabled="!validContainer"
                v-on:input="onEndingContainerInput($event)"
                v-model="endingContainerIndicator"
              />

              <div class="lux-input">
                <div class="lux-input-status">
                  {{ containerStatus }}
                </div>
              </div>
            </grid-item>
          </grid-container>
        </fieldset>
      </grid-item>
    </grid-container>
  </form>
</template>

<script>
import BatchFormMixin from "./batch_form_mixin";

import AbsoluteIdASpaceStatus from "./service_status";
import AbsoluteIdInputText from "./input_text";
import AbsoluteIdDataList from "./data_list";

export default {
  name: "MarcBatchForm",
  type: "Element",
  mixins: [BatchFormMixin],
  components: {
    "absolute-id-input-text": AbsoluteIdInputText
  },
  props: {
    action: {
      type: String,
      required: true
    },
    method: {
      type: String,
      default: "POST"
    },
    token: {
      type: String,
      default: null
    },
    value: {
      type: Object,
      default: function() {
        return {
          absolute_id: {
            barcode: null,
            location: null,
            container_profile: null,
            repository: null,
            resource: null,
            container: null
          },
          barcodes: [],
          batch_size: 1,
          valid: false
        }
      }
    },
    source: {
      type: String,
      default: "marc"
    },
    service: {
      type: Object,
      required: true
    },
    barcode: {
      type: String,
      default: ""
    },
    batchForm: {
      type: Boolean,
      default: false
    },
    batchSize: {
      type: Number,
      default: 1
    }
  },

  computed: {

    /**
     * Form validation
     */
    formValid: async function() {
      const selectedLocationId = await this.selectedLocationId;
      const selectedContainerProfileId = await this.selectedContainerProfileId;
      const selectedRepositoryId = await this.selectedRepositoryId;

      const output =
        this.parsedBarcode &&
        selectedLocationId &&
        selectedContainerProfileId &&
        selectedRepositoryId &&
        this.resourceTitle &&
        this.containerIndicator;

      return !!output;
    }
  },

  methods: {
    /**
     * Form validation
     */
    isFormValid: async function() {
      const selectedLocation = await this.selectedLocationId;
      const selectedRepository = await this.selectedRepositoryId;

      const output =
        this.parsedBarcode &&
        selectedLocation &&
        selectedRepository &&
        this.resourceTitle &&
        this.containerIndicator;
      return !!output;
    },

    getFormData: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      const selectedRepository = await this.selectedRepositoryId;

      const resourceTitle = await this.resourceTitle;
      const containerIndicator = await this.containerIndicator;

      const valid = await this.isFormValid();

      return {
        absolute_id: {
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: resourceTitle,
          container: containerIndicator
        },
        barcodes: this.barcodes,
        batch_size: this.batchSize,
        valid
      };
    },

    /**
     * This is needed for the data list
     */
    updateAbsoluteId: async function() {
      if (this.value.absolute_id) {
        if (this.value.absolute_id.location) {
          this.selectedLocationId = this.value.absolute_id.location;
        }

        if (this.value.absolute_id.container_profile) {
          this.selectedContainerProfileId = this.value.absolute_id.container_profile;
        }

        if (this.value.absolute_id.repository) {
          this.selectedRepositoryId = this.value.absolute_id.repository;
        }

        if (this.value.absolute_id.resource) {
          this.selectedResourceId = this.value.absolute_id.resource;
        }

        if (this.value.absolute_id.container) {
          this.selectedContainerId = this.value.absolute_id.container;
        }
      }
    }
  }
};
</script>
