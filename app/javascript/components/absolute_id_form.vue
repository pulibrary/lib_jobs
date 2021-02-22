<template>
  <form method="post" class="absolute-ids-form" v-bind:value="value" v-on:input="onInput" v-on:submit.prevent="submit">

    <grid-container>
      <grid-item columns="sm-12 lg-3">
        <fieldset class="absolute-ids-form--fields">
          <legend>Barcode</legend>
          <input-text
            id="next_code"
            class="absolute-ids-form--input-field"
            name="next_code"
            label="Input"
            :hide-label="true"
            placeholder="Barcode"
            helper="Barcode"
            :value="nextCode">
          </input-text>

          <input-text
            id="terminal_code"
            class="absolute-ids-form--input-field"
            name="terminal_code"
            label="Input"
            :hide-label="true"
            helper="Ending Barcode"
            :disabled="true"
            :value="terminalCode">
          </input-text>
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
            display-property="classification"
            v-model="selectedLocationId">
          </absolute-id-data-list>

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
            display-property="prefix"
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
              id="last_container_id"
              class="absolute-ids-form--input-field"
              name="last_container_id"
              label="Ending Box Number"
              :hide-label="true"
              helper="Ending Box Number"
              :placeholder="containerPlaceholder"
              :disabled="true"
              v-model="containerIndicator">
            </input-text>

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
    nextCode: {
      type: String,
      default: '0000000000000'
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

      // Remove this
      //selectedResourceId: resourceId,
      // Remove this
      //selectedContainerId: containerId,

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

      valid: false
    }
  },
  computed: {
    terminalCode: function () {
      const parsedCode = Number.parseInt(this.nextCode);
      const parsedSize = Number.parseInt(this.batchSize);
      const incremented = parsedCode + parsedSize;

      const encoded = incremented.toString();
      const formatted = encoded.padStart(13, 0);

      return formatted;
    },

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

    resources: async function () {
      if (!this.selectedRepositoryId) {
        return [];
      }

      const response = await this.getResources(this.selectedRepositoryId);
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
          barcode: this.nextCode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: resourceTitle,
          container: containerIndicator
        },
        valid
      };
    },

    formValid: async function () {
      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.getSelectedRepository();
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const output = this.nextCode && selectedLocation && selectedRepository && selectedResource && selectedContainer;
      return !!output;
    }
  },

  updated: async function () {
    this.$nextTick(function () {

      if (this.value && this.value.absolute_id && this.value.absolute_id.location) {
        if (!this.selectedLocationId) {
          this.selectedLocationId = this.value.absolute_id.location.id;
        }
      }

      if (this.value && this.value.absolute_id && this.value.absolute_id.container_profile) {
        if (!this.selectedContainerProfileId) {
          this.selectedContainerProfileId = this.value.absolute_id.container_profile.id;
        }
      }

      if (this.value && this.value.absolute_id && this.value.absolute_id.repository) {
        if (!this.selectedRepositoryId) {
          this.selectedRepositoryId = this.value.absolute_id.repository.id;
        }
      }

      if (this.value && this.value.absolute_id && this.value.absolute_id.resource) {
        if (!this.selectedResourceId) {
          this.selectedResourceId = this.value.absolute_id.resource.id;
        }
      }

      if (this.value && this.value.absolute_id && this.value.absolute_id.container) {
        if (!this.selectedContainerId) {
          this.selectedContainerId = this.value.absolute_id.container.id;
        }
      }
    });
  },

  mounted: async function () {
    const fetchedLocations = await this.locations;
    this.locationOptions = fetchedLocations.map((location) => {
      return {
        id: location.id,
        label: location.building,
        classification: location.classification,
        uri: location.uri
      };
    });

    const fetchedRepositories = await this.repositories;
    this.repositoryOptions = fetchedRepositories.map((repository) => {
      return {
        id: repository.id,
        label: repository.name,
        uri: repository.uri,
        repoCode: repository.repo_code
      };
    });

    const fetchedContainerProfiles = await this.containerProfiles;
    this.containerProfileOptions = fetchedContainerProfiles.map((containerProfile) => {
      return {
        id: containerProfile.id,
        label: containerProfile.name,
        prefix: containerProfile.prefix,
        uri: containerProfile.uri
      };
    });
  },

  methods: {
    isFormValid: async function () {
      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.getSelectedRepository();
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const output = this.nextCode && selectedLocation && selectedRepository && this.resourceTitle && this.containerIndicator;
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
          barcode: this.nextCode,
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

    searchResources: async function (queryParam) {
      let response;
      this.fetchingResources = true;

      try {
        response = await fetch(`/absolute-ids/repositories/${this.selectedRepositoryId}/resources/search/${queryParam}`, {
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
      } catch (error) {
        console.warn(error);
      }

      this.fetchingResources = false;
      return response;
    },

    searchContainers: async function (queryParam) {
      let response;
      this.fetchingContainers = true;

      try {
        response = await fetch(`/absolute-ids/repositories/${this.selectedRepositoryId}/containers/search/${queryParam}`, {
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
        this.validatingResource = true;

        const response = await this.searchResources(value);
        const resource = await response.json();

        this.validatingResource = false;

        if (resource) {
          this.validResource = true;
          this.validatedResource = true;
        }
      }
    },

    onContainerFocusOut: async function (event, value) {

      this.validContainer = false;
      this.validatedContainer = false;

      if (value.length > 0) {
        this.validatingContainer = true;

        const response = await this.searchContainers(value);
        const resource = await response.json();

        this.validatingContainer = false;

        if (resource) {
          this.validContainer = true;
          this.validatedContainer = true;
        }
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
      const fetchedResources = await this.fetchResources(this.selectedRepositoryId);
      this.resourceOptions = fetchedResources.map((resource) => {
        return {
          label: resource.title,
          uri: resource.uri,
          id: resource.id
        };
      });

      const fetchedContainers = await this.fetchContainers(this.selectedRepositoryId);
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

      const model = resolved.find( repo => repo.id.toString() === this.selectedRepositoryId );
      return model;
    },

    resourceClasses: async function () {
      const classes = ["absolute-ids-form--input-field"];

      const validatedResource = await this.validatedResource;
      const validResource = await this.validResource;
      const resourceTitle = await this.resourceTitle;

      console.log(validatedResource);
      console.log(validResource);
      console.log(resourceTitle);

      if (validatedResource) {
        classes.push('absolute-ids-form--input-field__validated');
      } else if (resourceTitle.length > 0 && !validResource) {
        classes.push('absolute-ids-form--input-field__invalid');
      }

      console.log(classes);
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

      console.log(classes);
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
