<template>
  <form method="post" class="absolute-ids-batch-form" v-on:submit.prevent="submit">

    <template v-for="(entry, index) in batch">
      <fieldset class="absolute-ids-batch-form--batch">
        <legend>Batch</legend>

        <absolute-id-form
          :key="batchKey(index)"
          v-model="batch[index]"
          :action="action"
          :token="token"
          :next-code="getNextCode(index, batchSize[index])"
          :disable-submit="true">
        </absolute-id-form>

        <fieldset class="absolute-ids-batch-form--batch-size">
          <legend>Batch Size</legend>
          <input-text
            :key="index"
            id="batch-size"
            name="batch[batch_size]"
            v-model="batchSize[index]"
            label="Input"
            :hide-label="true"
            helper="Number of Absolute IDs"
            size="small"
            @change="onChangeBatchSize($event, index)"></input-text>
        </fieldset>

        <button
          v-if="index > 0"
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-batch-form--remove"
          @click.prevent="onClickRemove(index)">Remove Batch</button>

      </fieldset>
    </template>

    <grid-container>
      <grid-item columns="lg-12 sm-12">
        <button
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-batch-form--add-form"
          @click.prevent="onClickAdd">Add Batch</button>
      </grid-item>

      <grid-item columns="lg-12 sm-12">
        <button
          data-v-b7851b04
          class="lux-button solid large lux-button absolute-ids-batch-form--submit"
          :disabled="!formValid">Generate</button>
      </grid-item>
    </grid-container>
  </form>
</template>

<script>
import AbsoluteIdForm from './absolute_id_form'

export default {
  name: 'AbsoluteIdsBatchForm',
  status: 'ready',
  release: '1.0.0',
  type: 'Element',
  components: {
    "absolute-id-form": AbsoluteIdForm
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
    nextCode: {
      type: String,
      default: '0000000000000'
    }
  },

  data: function () {
    return {
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
          batch_size: 1,
          valid: false
        }
      ],
      batchSize: [
        1
      ],
      barcodes: [],
      batchUpdates: 0
    }
  },

  computed: {
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
    },

    formData: function () {
      return {
        batch: this.batch
      };
    }
  },

  /*
  watch: {
    batch: function(newBatch, oldBatch) {
      //debugger;
      this.batch = newBatch;
    }
  },
  */

  mounted: async function () {
    this.barcodes.push(this.nextCode);

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
        batch_size: 1,
        valid: false
      };
    },

    onChangeBatchSize: function(event, batchIndex) {
      const entry = this.batch[batchIndex];

      if (!event.target.value) {
        entry.batch_size = null;
      } else {
        entry.batch_size = Number.parseInt(event.target.value);
      }

      this.batchSize[batchIndex] = entry.batch_size;
    },

    getNextCode: function (index, updatedValue) {
      const currentValue = this.batchSize[index];
      const previousValue = this.batchSize[index - 1];

      let batchSize;

      if (!currentValue) {
        batchSize = index;
      } else if (!previousValue && index === 0) {
        batchSize = index;
      } else if (!previousValue) {
        batchSize = index;
      } else {
        batchSize = Number.parseInt(previousValue);
      }

      let code;
      let incremented;
      if (index <= 1) {
        code = Number.parseInt(this.nextCode);
        incremented = code + batchSize;
      } else {
        const previousBarcode = this.barcodes[index - 1];
        code = Number.parseInt(previousBarcode);
        incremented = code + batchSize;
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
      let newBarcodeValue = Number.parseInt(this.nextCode);

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

      //this.batchUpdates++;
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
      const response = await this.postData(payload);

      event.target.disabled = false;
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
