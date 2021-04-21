<template>
  <form
    method="post"
    class="absolute-ids-form"
    v-bind:value="value"
    v-on:input="onInput"
    v-on:submit.prevent="submit"
  >
    <grid-container>
      <grid-item columns="sm-12 lg-3">
        <fieldset class="absolute-ids-form--fields">
          <legend>Barcode</legend>

          <input-text
            id="barcode"
            class="absolute-ids-form--input-field"
            name="barcode"
            label="Input"
            :hide-label="true"
            placeholder="Barcode"
            :helper="size > 1 ? 'Starting Barcode' : null"
            :maxlength="barcodeLength"
            v-on:input="onBarcodeInput($event)"
            :disabled="barcodeValid"
            :value="startingBarcode()"
          />
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
        </fieldset>
      </grid-item>

      <grid-item columns="sm-12 lg-9">
        <fieldset class="absolute-ids-form--fields">
          <legend>{{ sourceLegend }}</legend>

          <grid-container>
            <grid-item columns="sm-12 lg-12">
              <input-text
                id="location_id"
                class="absolute-ids-form--input-field"
                name="location_id"
                label="Location"
                :hide-label="true"
                helper="Location"
                :placeholder="locationPlaceholder"
                v-model="location"
              />

              <input-text
                id="container_profile_id"
                class="absolute-ids-form--input-field"
                name="container_profile_id"
                label="Container Profile"
                :hide-label="true"
                helper="Container Profile"
                :placeholder="containerProfilePlaceholder"
                v-model="containerProfile"
              />

              <input-text
                id="repository_id"
                class="absolute-ids-form--input-field"
                name="repository_id"
                label="Repository"
                :hide-label="true"
                helper="Repository"
                :placeholder="repositoryPlaceholder"
                v-model="repository"
              />
            </grid-item>

            <grid-item columns="sm-12 lg-12">
              <input-text
                id="resource_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedResource,
                  'absolute-ids-form--input-field__invalid':
                    callNumber.length > 0 && !validResource,
                  'absolute-ids-form--input-field': true
                }"
                name="resource_id"
                label="Call Number"
                :hide-label="true"
                helper="Call Number"
                :placeholder="resourcePlaceholder"
                :disabled="!repository || validatingResource"
                v-on:inputblur="onResourceFocusOut($event, callNumber)"
                v-model="callNumber"
              />

              <div class="lux-input">
                <div class="lux-input-field medium">
                  {{ resourceStatus }}
                </div>
              </div>
            </grid-item>

            <grid-item columns="sm-12 lg-9">
              <input-text
                id="container_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedContainer,
                  'absolute-ids-form--input-field__invalid':
                    boxIndex.length > 0 && !validContainer,
                  'absolute-ids-form--input-field': true
                }"
                name="container_id"
                label="Starting Box Number"
                :hide-label="true"
                helper="Starting Box Number"
                :placeholder="containerPlaceholder"
                :disabled="!repository || !callNumber || validatingContainer"
                v-on:inputblur="onContainerFocusOut($event, boxIndex)"
                v-model="boxIndex"
              >
              </input-text>

              <input-text
                id="ending_container_id"
                class="absolute-ids-form--input-field"
                name="ending_container_id"
                label="Ending Box Number (Optional)"
                :hide-label="true"
                helper="Ending Box Number"
                :placeholder="endingContainerPlaceholder"
                :disabled="!validContainer"
                v-on:input="onEndingContainerInput($event)"
                v-model="endingBoxIndex"
              >
              </input-text>

              <div class="lux-input">
                <div class="lux-input-field medium">
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
export default {
  name: "AbsoluteIdMarcForm",
  type: "Element",
  props: {
    action: {
      type: String,
      default: null
    },
    method: {
      type: String,
      default: "post"
    },
    token: {
      type: String,
      default: null
    },
    value: {
      type: Object,
      default: {
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
    },
    barcode: {
      type: String,
      default: ""
    },
    mode: {
      type: String,
      default: "aspace"
    },
    batchSize: {
      type: Number,
      default: 1
    }
  },

  data: function() {
    return {
      location: this.value.absolute_id.location,
      containerProfile: this.value.absolute_id.containerProfile,
      repository: this.value.absolute_id.repository,
      callNumber: this.value.absolute_id.resource || "",
      boxIndex: this.value.absolute_id.container || "",
      endingBoxIndex: "",

      validResource: false,
      validatedResource: false,

      validContainer: false,
      validatedContainer: false,

      barcodeLength: 13,
      barcodeValid: false,
      parsedBarcode: this.barcode,
      parsedEndingBarcode: "",
      barcodes: [],

      size: this.batchSize,

      valid: false
    };
  },

  computed: {
    sourceLegend: function() {
      let output;

      if (this.mode == "aspace") {
        output = "ArchivesSpace";
      } else if (this.mode == "marc") {
        output = "MARC";
      }

      return output;
    },

    resourceStatus: function() {
      if (this.validResource) {
        return "Call number is valid";
      } else if (this.validatingResource) {
        return "Validating call number...";
      } else if (this.repository) {
        return "Please enter a call number";
      } else {
        return "";
      }
    },

    containerStatus: function() {
      if (this.validContainer) {
        return "Box number is valid";
      } else if (this.validatingContainer) {
        return "Validating box number...";
      } else if (this.callNumber && this.validResource) {
        return "Please enter a box number";
      } else {
        return "";
      }
    },

    endingContainerPlaceholder: function() {
      if (this.validContainer) {
        return this.boxIndex;
      } else {
        return "No call number specified";
      }
    },

    locationPlaceholder: function() {
      let value = "Enter a location";

      /*
      if (this.fetchingLocations) {
        value = 'Loading...';
      } else if (this.locationOptions.length > 0) {
        value = 'Select a location';
      }
      */

      return value;
    },

    repositoryPlaceholder: function() {
      let value = "Enter a repository";

      /*
      if (this.fetchingRepositories) {
        value = 'Loading...';
      } else if (this.repositoryOptions.length > 0) {
        value = 'Select a repository';
      }
      */

      return value;
    },

    // Resources
    resources: async function() {
      return [];
    },

    resourcePlaceholder: function() {
      let value = "Enter a call number";

      /*
      if (this.repository) {
        value = 'Enter a call number';
      }
      */

      return value;
    },

    containerProfilePlaceholder: function() {
      let value = "Enter a container profile";

      /*
      if (this.fetchingRepositories) {
        value = 'Loading...';
      } else if (this.repositoryOptions.length > 0) {
        value = 'Select a container profile';
      }
      */

      return value;
    },

    containerPlaceholder: function() {
      let value = "Enter a box number";

      /*
      if (this.selectedResourceId) {
        value = 'Enter a box number';
      } else if (this.repository) {
        value = 'No call number specified';
      }
      */

      return value;
    },

    selectedResource: async function() {
      if (!this.selectedResourceId) {
        return null;
      }

      const resolved = await this.resources;
      const model = resolved.find(res => res.id === this.selectedResourceId);
      if (!model) {
        throw `Failed to find the model: ${this.selectedResourceId}`;
      }
      return model;
    },

    containers: async function() {
      if (!this.repository) {
        return null;
      }

      const response = await this.getContainers(this.repository);
      const models = response.json();

      return models;
    },

    formData: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;

      //const selectedRepository = await this.getSelectedRepository();
      const selectedRepository = this.repository;

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const valid = await this.formValid;

      return {
        absolute_id: {
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: this.callNumber,
          container: this.boxIndex
        },
        valid
      };
    },

    formValid: async function() {
      const selectedLocation = await this.selectedLocation;

      const repository = await this.repository;

      //const selectedRepository = await this.getSelectedRepository();

      const output =
        this.parsedBarcode &&
        selectedLocation &&
        this.inputRepository &&
        this.callNumber &&
        this.boxIndex;
      return !!output;
    }
  },

  updated: async function() {
    this.updateValue();

    const base = this.parsedBarcode.slice(0, -1);
    this.updateEndingBarcode(base);

    this.valid = await this.formValid;
  },

  methods: {
    updateAbsoluteId: async function() {
      if (this.value.absolute_id) {
        if (this.value.absolute_id.location) {
          this.location = this.value.absolute_id.location.id;
        }

        if (this.value.absolute_id.container_profile) {
          this.containerProfile = this.value.absolute_id.container_profile.id;
        }

        if (this.value.absolute_id.repository) {
          this.repository = this.value.absolute_id.repository.id;
        }

        if (this.value.absolute_id.resource) {
          this.selectedResourceId = this.value.absolute_id.resource.id;
        }

        if (this.value.absolute_id.container) {
          this.selectedContainerId = this.value.absolute_id.container.id;
        }
      }
    },

    updateValue: async function() {
      if (this.value) {
        await this.updateAbsoluteId();
      }
    },

    startingBarcode: function() {
      return this.parsedBarcode;
    },

    endingBarcode: function() {
      return this.parsedEndingBarcode;
    },

    generateChecksum: function(base) {
      const padded = `${base}0`;
      const len = padded.length;
      const parity = len % 2;
      let sum = 0;

      for (let i = len - 1; i >= 0; i--) {
        let d = parseInt(padded.charAt(i));
        if (i % 2 == parity) {
          d *= 2;
        }
        if (d > 9) {
          d -= 9;
        }
        sum += d;
      }

      const remainder = sum % 10;
      return remainder == 0 ? 0 : 10 - remainder;
    },

    updateBarcode: function(value) {
      if (value.length < 13) {
        this.barcodeLength = 13;
        this.barcodeValid = false;
      } else if (value.length == 13) {
        const checksum = this.generateChecksum(value);
        this.barcodeLength = 14;
        this.barcodeValid = true;

        this.parsedBarcode = `${value}${checksum}`;
      }
    },

    updateEndingBarcode: function(value) {
      if (value.length < 13 || this.size < 2) {
        return;
      }

      const parsed = Number.parseInt(value);
      const incremented = parsed + this.size - 1;

      const encoded = incremented.toString();
      const formatted = encoded.padStart(13, 0);
      const checksum = this.generateChecksum(formatted);

      this.parsedEndingBarcode = `${formatted}${checksum}`;
    },

    updateBarcodes: function() {
      for (const i of Array(this.size).keys()) {
        const base = this.parsedBarcode.slice(0, 13);
        const value = Number.parseInt(base) + i;
        const encoded = `${value}`;
        const incremented = encoded.padStart(13, 0);
        const checksum = this.generateChecksum(incremented);
        const newBarcode = `${incremented}${checksum}`;

        this.$set(this.barcodes, i, newBarcode);
      }
    },

    onBarcodeInput: function(value) {
      this.updateBarcode(value);
      this.updateEndingBarcode(value);
      this.updateBarcodes();
    },

    onEndingContainerInput: function(value) {
      const payload = {
        start: this.boxIndex,
        end: value
      };
      const firstIndex = Number.parseInt(this.boxIndex);
      const lastIndex = Number.parseInt(value);
      this.size = lastIndex - firstIndex + 1;
      this.updateBarcodes();

      this.$emit("input-size", payload);
    },

    isFormValid: async function() {
      const selectedLocation = await this.selectedLocation;
      //const selectedRepository = await this.getSelectedRepository();
      const selectedRepository = this.repository;
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      //const output = this.barcode && selectedLocation && selectedRepository && this.callNumber && this.boxIndex;
      const output =
        this.parsedBarcode &&
        selectedLocation &&
        selectedRepository &&
        this.callNumber &&
        this.boxIndex;
      return !!output;
    },

    getFormData: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      //const selectedRepository = await this.getSelectedRepository();
      const selectedRepository = this.repository;

      const callNumber = await this.callNumber;
      const boxIndex = await this.boxIndex;

      const barcodes = this.barcodes;
      const batchSize = this.size;
      const valid = await this.isFormValid();

      return {
        absolute_id: {
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: callNumber,
          container: boxIndex
        },
        barcodes: barcodes,
        batch_size: batchSize,
        valid
      };
    },

    onInput: async function() {
      const inputState = await this.getFormData();
      this.$emit("input", inputState);
    },

    onResourceFocusOut: async function(event, value) {
      this.validResource = false;
      this.validatedResource = false;

      if (value.length > 0) {
        /*
        const eadId = await this.callNumber;

        this.validatingResource = true;

        const response = await this.searchResources({ eadId });
        const resource = await response.json();

        this.validatingResource = false;

        if (resource) {
          this.validResource = true;
          this.validatedResource = true;
        }
        */

        this.validatingResource = false;
        this.validResource = true;
        this.validatedResource = true;
      }
    },

    onContainerFocusOut: async function(event, value) {
      this.validContainer = false;
      this.validatedContainer = false;

      if (value.length > 0) {
        /*
        const callNumber = await this.callNumber;
        this.validatingContainer = true;

        const response = await this.searchContainers({ indicator: value, callNumber });

        this.validatingContainer = false;
        if (!response) {
          return;
        }

        const resource = await response.json();

        if (resource) {
          this.validContainer = true;
          this.validatedContainer = true;
        }
        */

        this.validatingContainer = true;
        this.validatingContainer = false;

        this.validContainer = true;
        this.validatedContainer = true;
      }
    },

    fetchContainers: async function(repositoryId) {
      if (!repositoryId) {
        return [];
      }

      const response = await this.getContainers(repositoryId);
      const resources = response.json();

      return resources;
    },

    resourceClasses: async function() {
      const classes = ["absolute-ids-form--input-field"];

      const validatedResource = await this.validatedResource;
      const validResource = await this.validResource;
      const callNumber = await this.callNumber;

      if (validatedResource) {
        classes.push("absolute-ids-form--input-field__validated");
      } else if (callNumber.length > 0 && !validResource) {
        classes.push("absolute-ids-form--input-field__invalid");
      }

      return classes.join(" ");
    },

    containerClasses: async function() {
      const classes = ["absolute-ids-form--input-field"];

      const validatedContainer = await this.validatedContainer;
      const validContainer = await this.validContainer;
      const boxIndex = await this.boxIndex;

      if (validatedContainer) {
        classes.push("absolute-ids-form--input-field__validated");
      } else if (boxIndex.length > 0 && !validContainer) {
        classes.push("absolute-ids-form--input-field__invalid");
      }

      return classes.join(" ");
    },

    postData: async function(data = {}) {
      const response = await fetch(this.action, {
        method: this.method,
        mode: "cors",
        cache: "no-cache",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.token}`
        },
        redirect: "follow",
        referrerPolicy: "no-referrer",
        body: JSON.stringify(data)
      });

      return response;
    },

    submit: async function(event) {
      const payload = await this.formData;

      event.target.disabled = true;
      const response = await this.postData(payload);

      event.target.disabled = false;
      if (response.status === 302) {
        const redirectUrl = response.headers.get("Content-Type");
        window.location.assign(redirectUrl);
      } else {
        window.location.reload();
      }
    }
  }
};
</script>
