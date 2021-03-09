<template>
  <form method="post" class="absolute-ids-form" v-bind:value="value" v-on:input="onInput" v-on:submit.prevent="submit">

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
            helper="Starting Barcode"
            :maxlength="barcodeLength"
            v-on:input="onBarcodeInput($event)"
            :disabled="barcodeValid"
            :value="startingBarcode()"
          />
          <input-text
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
          <legend>ArchivesSpace</legend>

          <grid-container>
            <grid-item columns="sm-12 lg-12">
              <absolute-id-data-list
                id="location_id"
                class="absolute-ids-form--input-field"
                name="location_id"
                label="Location"
                :hide-label="true"
                helper="Location"
                :placeholder="locationPlaceholder"
                :disabled="fetchingLocations"
                :list="locationOptions"
                v-model="selectedLocationId"
              />

              <absolute-id-data-list
                id="container_profile_id"
                class="absolute-ids-form--input-field"
                name="container_profile_id"
                label="Container Profile"
                :hide-label="true"
                helper="Container Profile"
                :placeholder="containerProfilePlaceholder"
                :disabled="fetchingContainerProfiles"
                :list="containerProfileOptions"
                v-model="selectedContainerProfileId">
              </absolute-id-data-list>

              <absolute-id-data-list
                id="repository_id"
                class="absolute-ids-form--input-field"
                name="repository_id"
                label="Repository"
                :hide-label="true"
                helper="Repository"
                :placeholder="repositoryPlaceholder"
                :disabled="fetchingRepositories"
                :list="repositoryOptions"
                v-model="selectedRepositoryId"
                display-property="repoCode"
                v-on:input="changeRepositoryId($event)">
              </absolute-id-data-list>
          </grid-item>

          <grid-item columns="sm-12 lg-12">
            <input-text
              id="resource_id"
              v-bind:class="{ 'absolute-ids-form--input-field__validated': (validatedResource), 'absolute-ids-form--input-field__invalid': (resourceTitle.length > 0 && !validResource), 'absolute-ids-form--input-field': true }"
              name="resource_id"
              label="Call Number"
              :hide-label="true"
              helper="Call Number"
              :placeholder="resourcePlaceholder"
              :disabled="!selectedRepositoryId || validatingResource"
              v-on:inputblur="onResourceFocusOut($event, resourceTitle)"
              v-model="resourceTitle">
            </input-text>

            <div class="lux-input">
              <div class="lux-input-field medium">
                {{ resourceStatus }}
              </div>
            </div>
          </grid-item>

          <grid-item columns="sm-12 lg-9">
            <input-text
              id="container_id"
              v-bind:class="{ 'absolute-ids-form--input-field__validated': (validatedContainer), 'absolute-ids-form--input-field__invalid': (containerIndicator.length > 0 && !validContainer), 'absolute-ids-form--input-field': true }"
              name="container_id"
              label="Starting Box Number"
              :hide-label="true"
              helper="Starting Box Number"
              :placeholder="containerPlaceholder"
              :disabled="!selectedRepositoryId || !resourceTitle || validatingContainer"
              v-on:inputblur="onContainerFocusOut($event, containerIndicator)"
              v-model="containerIndicator">
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
              v-model="endingContainerIndicator">
            </input-text>

            <div class="lux-input">
              <div class="lux-input-field medium">
                {{ containerStatus }}
              </div>
            </div>
          </grid-item>
        </grid-container>
      </fieldset>

        <button
          v-if="!batchForm"
          data-v-b7851b04
          class="lux-button solid large lux-button absolute-ids-form--submit"
          :disabled="!formValid">Generate</button>
      </grid-item>

    </grid-container>
  </form>
</template>

<script>
import AbsoluteIdDataList from './absolute_id_data_list'

export default {
  name: 'AbsoluteIdsForm',
  status: 'ready',
  release: '1.0.0',
  type: 'Element',
  components: {
    "absolute-id-data-list": AbsoluteIdDataList
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
        batch_size: 1,
        valid: false
      }
    },
    barcode: {
      type: String,
      default: ''
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
  data: function () {
    const defaultLocation = this.value.absolute_id.location;
    let locationId = null;
    if (defaultLocation) {
      locationId = defaultLocation.id;
    }

    const defaultContainerProfile = this.value.absolute_id.container_profile;
    let containerProfileId = null;
    if (defaultContainerProfile) {
      containerProfileId = defaultContainerProfile.id;
    }

    const defaultRepository = this.value.absolute_id.repository;
    let repositoryId = null;
    if (defaultRepository) {
      repositoryId = defaultRepository.id;
    }

    const defaultResource = this.value.absolute_id.resource;
    let resourceTitle = "";
    if (defaultResource) {
      resourceTitle = defaultResource.title;
    }

    const defaultContainer = this.value.absolute_id.container;
    let containerIndicator = "";
    if (defaultContainer) {
      containerIndicator = defaultContainer.indicator;
    }

    return {
      selectedLocationId: locationId,
      selectedContainerProfileId: containerProfileId,
      selectedRepositoryId: repositoryId,

      resourceTitle,
      containerIndicator,

      locationOptions: [],
      fetchingLocations: false,

      repositoryOptions: [],
      fetchingRepositories: false,

      resourceOptions: [],
      fetchingResources: false,
      validResource: false,
      validatedResource: false,
      validatingResource: false,

      containerProfileOptions: [],
      fetchingContainerProfiles: false,

      containerOptions: [],
      fetchingContainers: false,
      validContainer: false,
      validatedContainer: false,
      validatingContainer: false,

      barcodeLength: 13,
      barcodeValid: false,
      parsedBarcode: this.barcode,
      parsedEndingBarcode: '',
      repositoryId: null,

      endingContainerIndicator: '',

      valid: false
    }
  },
  computed: {
    resourceStatus: function () {
      if (this.validResource) {
        return 'Call number is valid';
      } else if (this.validatingResource) {
        return 'Validating call number...';
      } else if (this.selectedRepositoryId) {
        return 'Please enter a call number';
      } else {
        return '';
      }
    },

    containerStatus: function () {
      if (this.validContainer) {
        return 'Box number is valid';
      } else if (this.validatingContainer) {
        return 'Validating box number...';
      } else if (this.resourceTitle && this.validResource) {
        return 'Please enter a box number';
      } else {
        return '';
      }
    },

    endingContainerPlaceholder: function () {
      if (this.validContainer) {
        return this.containerIndicator;
      } else {
        return 'No call number specified';
      }
    },

    // Locations
    locations: async function () {
      const response = await this.getLocations();
      const locations = response.json();

      return locations;
    },

    locationPlaceholder: function () {
      let value = 'No locations available';

      if (this.fetchingLocations) {
        value = 'Loading...';
      } else if (this.locationOptions.length > 0) {
        value = 'Select a location';
      }

      return value;
    },

    // Repositories
    repositories: async function () {
      const response = await this.getRepositories();
      const repositories = response.json();

      return repositories;
    },

    repositoryPlaceholder: function () {
      let value = 'No repositories available';

      if (this.fetchingRepositories) {
        value = 'Loading...';
      } else if (this.repositoryOptions.length > 0) {
        value = 'Select a repository';
      }

      return value;
    },

    // Resources
    resources: async function () {
      if (!this.selectedRepositoryId) {
        return [];
      }

      const response = await this.getResources(this.repositoryId);
      const models = response.json();

      return models;
    },

    resourcePlaceholder: function () {
      let value = 'No repository selected';

      if (this.selectedRepositoryId) {
        value = 'Enter a call number';
      }

      return value;
    },

    containerProfilePlaceholder: function () {
      let value = 'No container profiles available';

      if (this.fetchingRepositories) {
        value = 'Loading...';
      } else if (this.repositoryOptions.length > 0) {
        value = 'Select a container profile';
      }

      return value;
    },

    containerPlaceholder: function () {
      let value = 'No repository selected';

      if (this.selectedResourceId) {
        value = 'Enter a box number';
      } else if (this.selectedRepositoryId) {
        value = 'No call number specified';
      }

      return value;
    },

    selectedResource: async function () {
      if (!this.selectedResourceId) {
        return null;
      }

      const resolved = await this.resources;
      const model = resolved.find( res => res.id === this.selectedResourceId );
      if (!model) {
        throw `Failed to find the model: ${this.selectedResourceId}`;
      }
      return model;
    },

    containerProfiles: async function () {
      const response = await this.getContainerProfiles();
      const models = response.json();

      return models;
    },

    containers: async function () {
      if (!this.selectedRepositoryId) {
        return null;
      }

      const response = await this.getContainers(this.selectedRepositoryId);
      const models = response.json();

      return models;
    },

    selectedContainerProfile: async function () {
      if (!this.selectedContainerProfileId) {
        return null;
      }

      const resolved = await this.containerProfiles;
      const model = resolved.find( res => res.id === this.selectedContainerProfileId );
      if (!model) {
        throw `Failed to find the model: ${this.selectedContainerProfileId}`;
      }
      return model;
    },

    selectedContainer: async function () {
      if (!this.selectedContainerId) {
        return null;
      }

      const resolved = await this.containers;
      const model = resolved.find( res => res.id === this.selectedContainerId );
      return model;
    },

    selectedLocation: async function () {
      if (!this.selectedLocationId) {
        return null;
      }

      const resolved = await this.locations;
      const model = resolved.find( res => res.id === this.selectedLocationId );
      return model;
    },

    formData: async function () {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;

      const selectedRepository = await this.getSelectedRepository();

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const valid = await this.formValid;

      return {
        absolute_id: {
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: this.resourceTitle,
          container: this.containerIndicator
        },
        valid
      };
    },

    formValid: async function () {
      const selectedLocation = await this.selectedLocation;

      const selectedRepositoryId = await this.selectedRepositoryId;

      const selectedRepository = await this.getSelectedRepository();

      const output = this.parsedBarcode && selectedLocation && selectedRepository && this.resourceTitle && this.containerIndicator;
      return !!output;
    }
  },

  updated: async function () {

    this.updateValue();

    this.barcode = this.parsedBarcode;
    const base = this.barcode.slice(0, -1);
    this.updateEndingBarcode(base);

    this.valid = await this.formValid;
  },

  mounted: async function () {

    const fetchedLocations = await this.locations;
    this.locationOptions = fetchedLocations.map((location) => {
      const display = location.building;

      let label = location.classification;
      let selected = location.classification;
      if (location.area) {
        label = `${location.area} (${location.classification})`;
        selected = `${location.area} (${location.classification})`;
      } else if (location.building) {
        label = `${location.building} (${location.classification})`;
        selected = `${location.building} (${location.classification})`;
      }

      return {
        id: location.id,
        label: label,
        display: display,
        classification: location.classification,
        building: location.building,
        selected: selected,
        uri: location.uri
      };
    });

    const fetchedContainerProfiles = await this.containerProfiles;
    this.containerProfileOptions = fetchedContainerProfiles.map((containerProfile) => {
      const display = containerProfile.name;

      let label = containerProfile.name;
      let selected = containerProfile.name;
      if (containerProfile.prefix) {
        label = `${containerProfile.name} (${containerProfile.prefix})`;
        selected = `${containerProfile.name} (${containerProfile.prefix})`;
      }

      return {
        id: containerProfile.id,
        label: label,
        selected: selected,
        uri: containerProfile.uri
      };
    });

    const fetchedRepositories = await this.repositories;
    this.repositoryOptions = fetchedRepositories.map((repository) => {
      return {
        id: repository.id,
        label: repository.name,
        selected: repository.name,
        uri: repository.uri,
        repoCode: repository.repo_code
      };
    });
  },

  methods: {

    updateAbsoluteId: async function () {

      if (this.value.absolute_id) {
        if (this.value.absolute_id.location) {
          this.selectedLocationId = this.value.absolute_id.location.id;
        }

        if (this.value.absolute_id.container_profile) {
          this.selectedContainerProfileId = this.value.absolute_id.container_profile.id;
        }

        if (this.value.absolute_id.repository) {
          this.selectedRepositoryId = this.value.absolute_id.repository.id;
        }

        if (this.value.absolute_id.resource) {
          this.selectedResourceId = this.value.absolute_id.resource.id;
        }

        if (this.value.absolute_id.container) {
          this.selectedContainerId = this.value.absolute_id.container.id;
        }
      }
    },

    updateValue: async function () {
      if (this.value) {
        await this.updateAbsoluteId();
      }
    },

    startingBarcode: function () {
      return this.parsedBarcode;
    },

    endingBarcode: function () {
      return this.parsedEndingBarcode;
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

    updateBarcode: function (value) {
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

    updateEndingBarcode: function (value) {
      if (value.length < 13) {
        return;
      }

      const parsed = Number.parseInt(value);
      const parsedSize = Number.parseInt(this.batchSize);
      const incremented = parsed + parsedSize;

      const encoded = incremented.toString();
      const formatted = encoded.padStart(13, 0);
      const checksum = this.generateChecksum(formatted);

      this.parsedEndingBarcode = `${formatted}${checksum}`;
    },

    onBarcodeInput: function (value) {
      this.updateBarcode(value);
      this.updateEndingBarcode(value);
    },

    onEndingContainerInput: function (value) {
      const payload = {
        'start': this.containerIndicator,
        'end': value
      };

      this.$emit('input-size', payload);
    },

    isFormValid: async function () {
      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.getSelectedRepository();
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      //const output = this.barcode && selectedLocation && selectedRepository && this.resourceTitle && this.containerIndicator;
      const output = this.barcode && selectedLocation && selectedRepository && this.resourceTitle && this.containerIndicator;
      return !!output;
    },

    getFormData: async function () {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      const selectedRepository = await this.getSelectedRepository();

      const resourceTitle = await this.resourceTitle;
      const containerIndicator = await this.containerIndicator;

      const batchSize = this.batchSize;
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
        batch_size: batchSize,
        valid,
      };
    },

    onInput: async function () {
      const inputState = await this.getFormData();
      this.$emit('input', inputState);
    },

    searchResources: async function ({ eadId }) {
      const payload = {
        eadId
      };

      let response;
      this.fetchingResources = true;

      try {
        response = await fetch(`/absolute-ids/repositories/${this.selectedRepositoryId}/resources/search`, {
          method: 'POST',
          mode: 'cors',
          cache: 'no-cache',
          credentials: 'same-origin',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.token}`
          },
          redirect: 'follow',
          referrerPolicy: 'no-referrer',
          body: JSON.stringify(payload)
        });
      } catch (error) {
        console.warn(error);
      }

      this.fetchingResources = false;
      return response;
    },

    searchContainers: async function ({ indicator, resourceTitle }) {
      const payload = {
        indicator,
        resourceTitle
      };

      let response;
      this.fetchingContainers = true;

      try {
        response = await fetch(`/absolute-ids/repositories/${this.selectedRepositoryId}/containers/search`, {
          method: 'POST',
          mode: 'cors',
          cache: 'no-cache',
          credentials: 'same-origin',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.token}`
          },
          redirect: 'follow',
          referrerPolicy: 'no-referrer',
          body: JSON.stringify(payload)
        });
      } catch(error) {
        console.warn(error);
      }

      this.fetchingContainers = false;
      return response;
    },

    onResourceFocusOut: async function (event, value) {

      this.validResource = false;
      this.validatedResource = false;

      if (value.length > 0) {
        /*
        const eadId = await this.resourceTitle;

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

    onContainerFocusOut: async function (event, value) {
      this.validContainer = false;
      this.validatedContainer = false;

      if (value.length > 0) {
        /*
        const resourceTitle = await this.resourceTitle;
        this.validatingContainer = true;

        const response = await this.searchContainers({ indicator: value, resourceTitle });

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

    getResources: async function (repositoryId) {
      this.fetchingResources = true;

      const response = await fetch(`/absolute-ids/repositories/${repositoryId}/resources`, {
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

      this.fetchingResources = false;
      return response;
    },

    fetchResources: async function (repositoryId) {
      if (!repositoryId) {
        return [];
      }

      const response = await this.getResources(repositoryId);
      const resources = response.json();

      return resources;
    },

    changeRepositoryId: async function (newId) {
      this.repositoryId = newId;

      const fetchedResources = await this.fetchResources(this.repositoryId);
      this.resourceOptions = fetchedResources.map((resource) => {
        return {
          label: resource.title,
          uri: resource.uri,
          id: resource.id
        };
      });

      const fetchedContainers = await this.fetchContainers(this.repositoryId);
      this.containerOptions = fetchedContainers.map((resource) => {
        return {
          label: resource.indicator,
          uri: resource.uri,
          id: resource.id
        };
      });
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

      try {
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
      } catch (e) {

        this.fetchingLocations = false;
        return;
      }

      //this.fetchingLocations = false;
      //return response;
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

    getContainers: async function (repositoryId) {
      this.fetchingContainers = true;

      const response = await fetch(`/absolute-ids/repositories/${repositoryId}/containers`, {
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

      this.fetchingContainers = false;
      return response;
    },

    fetchContainers: async function (repositoryId) {
      if (!repositoryId) {
        return [];
      }

      const response = await this.getContainers(repositoryId);
      const resources = response.json();

      return resources;
    },

    getSelectedRepository: async function () {
      if (!this.selectedRepositoryId) {
        return null;
      }

      const resolved = await this.repositories;

      const model = resolved.find(repo => repo.id.toString() === this.selectedRepositoryId);
      return model;
    },

    resourceClasses: async function () {
      const classes = ["absolute-ids-form--input-field"];

      const validatedResource = await this.validatedResource;
      const validResource = await this.validResource;
      const resourceTitle = await this.resourceTitle;

      if (validatedResource) {
        classes.push('absolute-ids-form--input-field__validated');
      } else if (resourceTitle.length > 0 && !validResource) {
        classes.push('absolute-ids-form--input-field__invalid');
      }

      return classes.join(' ');
    },

    containerClasses: async function () {
      const classes = ["absolute-ids-form--input-field"];

      const validatedContainer = await this.validatedContainer;
      const validContainer = await this.validContainer;
      const containerIndicator = await this.containerIndicator;

      if (validatedContainer) {
        classes.push('absolute-ids-form--input-field__validated');
      } else if (containerIndicator.length > 0 && !validContainer) {
        classes.push('absolute-ids-form--input-field__invalid');
      }

      return classes.join(' ');
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
