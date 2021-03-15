<template>
  <form method="post" class="absolute-ids-batch-form" v-on:submit.prevent="submit">
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
            id: 'marc',
            disabled: true
          }
        ]"
        v-on:change="onChangeMode"
      />
    </div>
    <template v-for="(entry, index) in batch">
      <fieldset class="absolute-ids-batch-form--batch">
        <legend>New Batch</legend>

        <absolute-id-aspace-form
          v-if="source == 'aspace'"
          :key="batchKey(index)"

          v-model="batch[index]"
          :action="action"
          service-status-action="/services/archivesspace"
          :token="token"
          :source="source"
          :barcode="generateBarcode(index, batchSize[index])"

          :batch-form="true"
          :batch-size="batchSize[index]"

          v-on:input-size="updateBatchSize($event, index)"
        />
        <absolute-id-marc-form
          v-else-if="source == 'marc'"
          :key="batchKey(index)"

          v-model="batch[index]"
          :action="action"
          :token="token"
          :source="source"
          :barcode="generateBarcode(index, batchSize[index])"

          :batch-form="true"
          :batch-size="batchSize[index]"

          v-on:input-size="updateBatchSize($event, index)"
        />

        <fieldset class="absolute-ids-batch-form--batch-size">
          <legend>Size</legend>
          <input-text
            :key="index"
            id="batch-size"
            name="batch[batch_size]"
            :value="getBatchSize(index)"
            label="Input"
            :hide-label="true"
            helper="Number of Absolute IDs"
            size="small"
            :disabled="true"
            >
          </input-text>

          <button
            v-if="index > 0"
            data-v-b7851b04
            class="lux-button solid lux-button absolute-ids-batch-form--remove"
            :disabled="submitting"
            @click.prevent="onClickRemove(index)">Remove Batch</button>
        </fieldset>
      </fieldset>
    </template>

    <grid-container>
      <grid-item columns="lg-6 sm-6" class="absolute-ids-batch-form__add-batch">
        <button
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-batch-form--add-form"
          :disabled="submitting"
          @click.prevent="onClickAdd">Add Batch</button>
      </grid-item>

      <grid-item columns="lg-6 sm-6" class="absolute-ids-batch-form__submit">
        <button
          data-v-b7851b04
          :class="submitButtonClass"
          :disabled="submitting || !formValid"
        >{{ submitButtonTextContent }}</button>
      </grid-item>
    </grid-container>
  </form>
</template>

<script>
import AbsoluteIdASpaceForm from './absolute_id_form'
import AbsoluteIdMarcForm from './absolute_id_marc_form'

export default {
  name: 'AbsoluteIdsBatchForm',
  type: 'Element',
  components: {
    "absolute-id-aspace-form": AbsoluteIdASpaceForm,
    "absolute-id-marc-form": AbsoluteIdMarcForm
  },
  props: {
    action: {
      type: String,
      default: null
    },
    method: {
      type: String,
      default: 'post'
    },
    token: {
      type: String,
      default: null
    },
    barcode: {
      type: String,
      default: ''
    }
  },

  data: function () {
    return {
      source: 'aspace',
      batch: [
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
          valid: false
        }
      ],
      batchSize: [
        1
      ],
      barcodes: [],
      batchUpdates: 0,
      submitting: false
    }
  },

  computed: {
    submitButtonClass: function () {
      const values = {
        'lux-button': true,
        'solid': true,
        'large': true,
        'absolute-ids-batch-form__submit-button': true,
        'absolute-ids-batch-form__submit-button--in-progress': this.submitting
      };

      return values;
    },

    submitButtonTextContent: function () {
      let output;

      if (this.submitting) {
        output = 'Generating';
      } else {
        output = 'Generate';
      }

      return output;
    },

    locations: async function () {
      const response = await this.getLocations();
      const locations = response.json();

      return locations;
    },

    repositories: async function () {
      const response = await this.getRepositories();
      const repositories = response.json();

      return repositories;
    },

    containerProfiles: async function () {
      const response = await this.getContainerProfiles();
      const models = response.json();

      return models;
    },

    formValid: function () {
      return true;

      // Enable this once the performance issues are finished
      /*
      return this.batch.map( (b) => {
        return b.absolute_id && b.absolute_id.container && b.absolute_id.container_profile && b.absolute_id.location && b.absolute_id.repository && b.absolute_id.resource;
      } ).reduce( (u,v) => (u && v) );
      */
    },

    formData: async function () {
      const resolvedBatch = this.batch;

      return {
        batch: resolvedBatch
      };
    }
  },

  mounted: async function () {
    /*
    if (this.barcodes.length > 0) {
      this.barcodes.push(this.barcode);
    }
    */

    const fetchedLocations = await this.locations;
    this.locationOptions = fetchedLocations.map((location) => {
      return {
        id: location.id,
        label: location.building,
        uri: location.uri
      };
    });

    const fetchedRepositories = await this.repositories;
    this.repositoryOptions = fetchedRepositories.map((repository) => {
      return {
        id: repository.id,
        label: repository.name,
        uri: repository.uri
      };
    });

    const fetchedContainerProfiles = await this.containerProfiles;
    this.containerProfileOptions = fetchedContainerProfiles.map((containerProfile) => {
      return {
        id: containerProfile.id,
        label: containerProfile.name,
        uri: containerProfile.uri
      };
    });
  },

  methods: {
    onChangeMode: function (changed) {
      this.source = changed;
    },

    batchKey: function (index) {
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
        valid: false
      };
    },

    generateBarcode: function (index, updatedValue) {
      if (this.barcode.length < 1) {
        return this.barcode;
      }

      const currentValue = this.batchSize[index];
      const previousValue = this.batchSize[index - 1];

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

    removeBarcode: function (index) {
      const u = this.barcodes.slice(0, index);
      const v = this.barcodes.slice(index + 1, this.barcodes.length);
      const output = u.concat(v);

      return output;
    },

    removeBatchSize: function (index) {
      const u = this.batchSize.slice(0, index);
      const v = this.batchSize.slice(index + 1, this.batchSize.length);
      const output = u.concat(v);

      return output;
    },

    removeBatch: function (index) {
      const u = this.batch.slice(0, index);
      const v = this.batch.slice(index + 1, this.batch.length);
      const output = u.concat(v);

      return output;
    },

    onClickRemove: function (index) {
      this.barcode = this.removeBarcode(index);
      this.batchSize = this.removeBatchSize(index);
      this.batch = this.removeBatch(index);
    },

    onClickAdd: function (event) {
      let newBarcodeValue = Number.parseInt(this.barcode);

      if (this.batchSize.length === 1) {
        newBarcodeValue = newBarcode + 1;
      } else {
        for (let i = 0; i < this.batchSize.length; i++) {
          newBarcodeValue = newBarcodeValue + this.batchSize[i];
        }
      }

      const encoded = newBarcodeValue.toString();
      const newBarcode = encoded.padStart(13, 0);

      this.barcodes.push(newBarcode);
      this.batchSize.push(1);

      const newAbsoluteId = this.buildAbsoluteId();
      this.batch.push(newAbsoluteId);
    },

    getRepositories: async function () {
      this.fetchingRepositories = true;

      const response = await fetch('/absolute-ids/repositories', {
            method: 'GET',
            mode: 'cors',
            cache: 'no-cache',
            credentials: 'same-origin',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${this.token}`
            },
            redirect: 'follow',
            referrerPolicy: 'no-referrer'
      });

      this.fetchingRepositories = false;
      return response;
    },

    getLocations: async function () {
      this.fetchingLocations = true;

      const response = await fetch('/absolute-ids/locations', {
            method: 'GET',
            mode: 'cors',
            cache: 'no-cache',
            credentials: 'same-origin',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${this.token}`
            },
            redirect: 'follow',
            referrerPolicy: 'no-referrer'
      });

      this.fetchingLocations = false;
      return response;
    },

    getContainerProfiles: async function () {
      this.fetchingContainerProfiles = true;

      const response = await fetch('/absolute-ids/container-profiles', {
        method: 'GET',
        mode: 'cors',
        cache: 'no-cache',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.token}`
        },
        redirect: 'follow',
        referrerPolicy: 'no-referrer'
      });

      this.fetchingContainerProfiles = false;
      return response;
    },

    getBatchSize: function (index) {
      return this.batchSize[index];
    },

    generateChecksum: function (base) {
      const padded = `${base}0`;
      const len = padded.length;
      const parity = len % 2;
      let sum = 0;

      for (let i = len-1; i >= 0; i--) {
        let d = parseInt(padded.charAt(i));
        if (i % 2 == parity) { d *= 2 };
        if (d > 9) { d -= 9 };
        sum += d;
      }

      const remainder = sum % 10;
      return remainder == 0 ? 0 : 10 - remainder;
    },

    updateBatchSize: async function (payload, batchIndex) {
      const start = payload.start;
      const end = payload.end;

      if (end.length < 1) {
        return;
      }

      let size = Number.parseInt(end) - Number.parseInt(start) + 1;
      if (size < 1) {
        size = 1;
      }

      const batch = await this.batch[batchIndex];

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
        this.$set(this.batchSize, batchIndex, size);

        batch.batch_size = size;

        // Update the batch
        this.$set(this.batch, batchIndex, batch);
      }
    },

    postData: async function (data = {}) {
      const response = await fetch(this.action, {
        method: this.method,
        mode: 'cors',
        cache: 'no-cache',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${this.token}`
        },
        redirect: 'follow',
        referrerPolicy: 'no-referrer',
        body: JSON.stringify(data)
      });

      return response;
    },

    submit: async function (event) {
      const payload = await this.formData;

      event.target.disabled = true;

      this.submitting = true;
      const response = await this.postData(payload);

      if (response.status === 302) {
        const redirectUrl = response.headers.get('Content-Type');
        window.location.assign(redirectUrl);
      } else {
        window.location.reload();
      }
    },
  }
}

</script>
