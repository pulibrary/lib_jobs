<template>
  <form
    method="post"
    class="absolute-ids-batch-form"
    v-on:submit.prevent="submit"
  >
    <div class="absolute-ids-batch-form--source">
      <input-radio
        id="source"
        vertical
        :options="[
          {
            name: 'radio-group-name',
            label: 'ArchivesSpace Resources',
            value: 'aspace',
            id: 'aspace',
            checked: true
          },
          {
            name: 'radio-group-name',
            label: 'MARC Records',
            value: 'marc',
            id: 'marc'
          }
        ]"
        v-on:change="onChangeMode"
      />
    </div>
    <template v-for="(entry, index) in batches">
      <fieldset class="absolute-ids-batch-form--batch">
        <legend>New Batch</legend>

        <aspace-batch-form
          v-if="source == 'aspace'"
          :key="batchKey(index)"
          v-model="batches[index]"
          :action="action"
          :token="token"
          :source="source"
          :service="service"
          :barcode="generateBarcode(index, batchSizes[index])"
          :locations="locations"
          :container-profiles="containerProfiles"
          :repositories="repositories"
          :batch-size="batchSizes[index]"
          :batch-form="true"
          :batch-size="batchSize[index]"
          v-on:input-size="updateBatchSize($event, index)"
        />
        <marc-batch-form
          v-else-if="source == 'marc'"
          :key="batchKey(index)"
          v-model="batches[index]"
          :action="action"
          :token="token"
          :source="source"
          :service="service"
          :barcode="generateBarcode(index, batchSizes[index])"
          :batch-size="batchSizes[index]"
          :batch-form="true"
          v-on:input-size="updateBatchSize($event, index)"
        />

        <fieldset class="absolute-ids-batch-form--batch-size">
          <legend>Size</legend>
          <input-text
            :key="index"
            id="batch-size"
            name="batches[batch_size]"
            :value="getBatchSize(index)"
            label="Input"
            :hide-label="true"
            helper="Number of Absolute IDs"
            size="small"
            :disabled="true"
          />
          <button
            v-if="index > 0"
            data-v-b7851b04
            class="lux-button solid lux-button absolute-ids-batch-form--remove"
            :disabled="submitting"
            @click.prevent="onClickRemove(index)"
          >
            Remove Batch
          </button>
        </fieldset>
      </fieldset>
    </template>

    <grid-container>
      <grid-item columns="lg-6 sm-6" class="absolute-ids-batch-form__add-batch">
        <button
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-batch-form--add-form"
          :disabled="submitting"
          @click.prevent="onClickAdd"
        >
          Add Batch
        </button>
      </grid-item>

      <grid-item columns="lg-6 sm-6" class="absolute-ids-batch-form__submit">
        <button
          data-v-b7851b04
          :class="submitButtonClass"
          :disabled="submitting || !formValid"
        >
          {{ submitButtonTextContent }}
        </button>
      </grid-item>
    </grid-container>
  </form>
</template>

<script>
import ASpaceBatchForm from "./aspace_batch_form";
import MarcBatchForm from "./marc_batch_form";

export default {
  name: "AbsoluteIdSessionForm",
  type: "Element",
  components: {
    "aspace-batch-form": ASpaceBatchForm,
    "marc-batch-form": MarcBatchForm
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
    service: {
      type: Object,
      required: true
    }
  },

  data: function() {
    return {
      fetchedLocations: [],
      fetchedContainerProfiles: [],
      fetchedRepositories: [],

      source: "aspace",
      barcode: "",
      batches: [
        {
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
          source: this.source,
          valid: false
        }
      ],
      batchSizes: [1],
      barcodes: [],
      batchUpdates: 0,
      submitting: false
    };
  },

  computed: {
    submitButtonClass: function() {
      const values = {
        "lux-button": true,
        solid: true,
        large: true,
        "absolute-ids-batch-form__submit-button": true,
        "absolute-ids-batch-form__submit-button--in-progress": this.submitting
      };

      return values;
    },

    submitButtonTextContent: function() {
      let output;

      if (this.submitting) {
        output = "Generating";
      } else {
        output = "Generate";
      }

      return output;
    },

    locations: async function() {
      let locations = [];

      try {
        const response = await this.getLocations();
        locations = await response.json();
      } catch (error) {
        console.warn(
          `Failed to retrieve the locations from ${this.service.locations}: ${error}`
        );
      }

      return locations;
    },

    containerProfiles: async function() {
      let containerProfiles = [];

      try {
        const response = await this.getContainerProfiles();
        containerProfiles = await response.json();
      } catch (error) {
        console.warn(
          `Failed to retrieve the container profiles from ${this.service.containerProfiles}: ${error}`
        );
      }

      return containerProfiles;
    },

    repositories: async function() {
      let repositories = [];

      try {
        const response = await this.getRepositories();
        repositories = await response.json();
      } catch (error) {
        console.warn(
          `Failed to retrieve the repositories from ${this.service.repositories}: ${error}`
        );
      }

      return repositories;
    },

    formValid: function() {
      // Enable this once the performance issues are finished
      const values = this.batches.map(batch => {
        return batch.valid;
      });

      // This is disabled for attempting to restore system spec.
      // return values.reduce((u, v) => u && v);
      return true;
    },

    formData: async function() {
      return {
        batches: this.batches
      };
    }
  },

  methods: {
    onChangeMode: function(changed) {
      this.source = changed;
    },

    batchKey: function(index) {
      return index + this.batchUpdates;
    },

    buildAbsoluteId: function() {
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
        source: this.source,
        valid: false
      };
    },

    generateBarcode: function(index, updatedValue) {
      if (this.barcode.length < 1) {
        return this.barcode;
      }

      const currentValue = this.batchSizes[index];
      const previousValue = this.batchSizes[index - 1];

      let batchSize;

      if (!currentValue) {
        batchSize = index;
      } else if (!previousValue) {
        batchSize = index;
      } else {
        batchSize = Number.parseInt(previousValue);
      }

      let code;
      let incremented;

      if (index < 1) {
        code = Number.parseInt(this.barcode);
        incremented = code + batchSize;
      } else {
        const previousBarcode = this.barcodes[index - 1];
        code = Number.parseInt(previousBarcode);
        incremented = code + batchSize + 1;
      }

      const encoded = incremented.toString();
      const output = encoded.padStart(13, 0);
      this.barcodes[index] = output;

      return output;
    },

    removeBarcode: function(index) {
      const u = this.barcodes.slice(0, index);
      const v = this.barcodes.slice(index + 1, this.barcodes.length);
      const output = u.concat(v);

      return output;
    },

    removeBatchSize: function(index) {
      const u = this.batchSizes.slice(0, index);
      const v = this.batchSizes.slice(index + 1, this.batchSizes.length);
      const output = u.concat(v);

      return output;
    },

    removeBatch: function(index) {
      const u = this.batches.slice(0, index);
      const v = this.batches.slice(index + 1, this.batches.length);
      const output = u.concat(v);

      return output;
    },

    onClickRemove: function(index) {
      this.barcode = this.removeBarcode(index);
      this.batchSizes = this.removeBatchSize(index);
      this.batches = this.removeBatch(index);
    },

    onClickAdd: function(event) {
      let newBarcodeValue = Number.parseInt(this.barcode);

      if (this.batchSizes.length === 1) {
        newBarcodeValue = newBarcode + 1;
      } else {
        for (let i = 0; i < this.batchSizes.length; i++) {
          newBarcodeValue = newBarcodeValue + this.batchSizes[i];
        }
      }

      const encoded = newBarcodeValue.toString();
      const newBarcode = encoded.padStart(13, 0);

      this.barcodes.push(newBarcode);
      this.batchSizes.push(1);

      const newAbsoluteId = this.buildAbsoluteId();
      this.batches.push(newAbsoluteId);
    },

    /*
    getLocations: async function() {
      let response = null;

      this.fetchingLocations = true;

      response = await fetch(this.service.locations, {
    */

    getRepositories: async function() {
      this.fetchingRepositories = true;

      const response = await fetch(this.service.repositories, {
        method: "GET",
        mode: "cors",
        cache: "no-cache",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.token}`
        },
        redirect: "follow",
        referrerPolicy: "no-referrer"
      });

      this.fetchingLocations = false;
      return response;
    },

    /*
    getContainerProfiles: async function() {
      let response = null;

      this.fetchingContainerProfiles = true;

      response = await fetch(this.service.containerProfiles, {
    */

    getLocations: async function() {
      this.fetchingLocations = true;

      const response = await fetch(this.service.locations, {
        method: "GET",
        mode: "cors",
        cache: "no-cache",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.token}`
        },
        redirect: "follow",
        referrerPolicy: "no-referrer"
      });

      this.fetchingContainerProfiles = false;
      return response;
    },

    /*
    getRepositories: async function() {
      let response = null;

      this.fetchingRepositories = true;

      response = await fetch(this.service.repositories, {
        //
    */

    getContainerProfiles: async function() {
      this.fetchingContainerProfiles = true;

      const response = await fetch(this.service.containerProfiles, {
        method: "GET",
        mode: "cors",
        cache: "no-cache",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.token}`
        },
        redirect: "follow",
        referrerPolicy: "no-referrer"
      });

      this.fetchingRepositories = false;
      return response;
    },

    getBatchSize: function(index) {
      return this.batchSizes[index];
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

    updateBatchSize: async function(payload, batchIndex) {
      const start = payload.start;
      const end = payload.end;

      if (end.length < 1) {
        return;
      }

      let size = Number.parseInt(end) - Number.parseInt(start) + 1;
      if (size < 1) {
        size = 1;
      }

      const batch = await this.batches[batchIndex];

      if (batch) {
        const absoluteId = batch.absolute_id;
        const barcode = absoluteId.barcode;

        // Update the barcodes
        const batchBarcodes = [];
        for (const i of Array(size).keys()) {
          const base = barcode.slice(0, 13);
          const value = Number.parseInt(base) + i;
          const encoded = `${value}`;
          const incremented = encoded.padStart(13, 0);
          const checksum = this.generateChecksum(incremented);
          const newBarcode = `${incremented}${checksum}`;

          batchBarcodes.push(newBarcode);
        }
        this.$set(this.batchSizes, batchIndex, size);

        batch.batch_size = size;

        // Update the batch
        this.$set(this.batches, batchIndex, batch);
      }
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

      this.submitting = true;
      const response = await this.postData(payload);

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
