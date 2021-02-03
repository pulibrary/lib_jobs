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
        </fieldset>
      </grid-item>

      <grid-item columns="sm-12 lg-9">
        <fieldset class="absolute-ids-form--fields">
          <legend>ArchivesSpace</legend>

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
            v-on:input="changeRepositoryId($event)">
          </absolute-id-data-list>

          <absolute-id-data-list
            id="resource_id"
            class="absolute-ids-form--input-field"
            name="resource_id"
            label="Resource"
            :hide-label="true"
            helper="Resource"
            :placeholder="resourcePlaceholder"
            :disabled="resourceOptions.length < 1"
            :list="resourceOptions"
            v-model="selectedResourceId">
          </absolute-id-data-list>

          <absolute-id-data-list
            id="container_id"
            class="absolute-ids-form--input-field"
            name="container_id"
            label="Container"
            :hide-label="true"
            helper="Container"
            :placeholder="containerPlaceholder"
            :disabled="containerOptions.length < 1"
            :list="containerOptions"
            v-model="selectedContainerId">
          </absolute-id-data-list>
        </fieldset>

        <button
          v-if="!disableSubmit"
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
    disableSubmit: {
      type: Boolean,
      default: false
    }
  },
  data: function () {
    //debugger;
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
    let resourceId = null;
    if (defaultResource) {
      resourceId = defaultResource.id;
    }

    const defaultContainer = this.value.absolute_id.container;
    let containerId = null;
    if (defaultContainer) {
      containerId = defaultContainer.id;
    }
    //debugger;

    return {
      selectedLocationId: locationId,
      selectedContainerProfileId: containerProfileId,
      selectedRepositoryId: repositoryId,
      selectedResourceId: resourceId,
      selectedContainerId: containerId,

      locationOptions: [],
      fetchingLocations: false,

      repositoryOptions: [],
      fetchingRepositories: false,

      resourceOptions: [],
      fetchingResources: false,

      containerProfileOptions: [],
      fetchingContainerProfiles: false,

      containerOptions: [],
      fetchingContainers: false,

      valid: false,

      batchSize: 1
    }
  },
  computed: {
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

    selectedRepository: async function () {
      if (!this.selectedRepositoryId) {
        return null;
      }

      const resolved = await this.repositories;

      const model = resolved.find( repo => repo.id === this.selectedRepositoryId );
      return model;
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

      if (this.fetchingResources) {
        value = 'Loading...';
      } else if (this.selectedRepositoryId && this.resourceOptions.length < 1) {
        value = 'No resources available';
      } else if (this.resourceOptions.length > 1) {
        value = 'Select a resource';
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

      if (this.fetchingContainers) {
        value = 'Loading...';
      } else if (this.selectedRepositoryId && this.containerOptions.length < 1) {
        value = 'No containers available';
      } else if (this.containerOptions.length > 1) {
        value = 'Select a container';
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

    // This might need to be removed
    formData: async function () {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      const selectedRepository = await this.selectedRepository;

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const valid = await this.formData;

      return {
        absolute_id: {
          barcode: this.nextCode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: selectedResource,
          container: selectedContainer
        },
        valid
      };
    },

    formValid: async function () {
      //return this.nextCode && this.selectedLocation && this.selectedRepository && this.selectedResource && this.selectedContainer;
      //const output = this.nextCode && this.selectedLocation && this.selectedRepository && this.selectedResource && this.selectedContainer;

      //this.value.valid = output;

      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.selectedRepository;
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const output = this.nextCode && selectedLocation && selectedRepository && selectedResource && selectedContainer;
      return !!output;
    }
  },

  updated: async function () {
    //debugger;
    //console.log(this);

    this.$nextTick(function () {

      if (this.value && this.value.absolute_id && this.value.absolute_id.location) {
        //console.log(this);
        if (!this.selectedLocationId) {
          this.selectedLocationId = this.value.absolute_id.location.id;
          //console.log(this);
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
    /*
    resources: async function () {
      if (!this.selectedRepositoryId) {
        return [];
      }

      const response = await this.getResources(this.selectedRepositoryId);
      const models = response.json();

      return models;
    },
    */

    /*
    getResourceOptions: async function () {

    },
    */

    isFormValid: async function () {
      //return this.nextCode && this.selectedLocation && this.selectedRepository && this.selectedResource && this.selectedContainer;
      //const output = this.nextCode && this.selectedLocation && this.selectedRepository && this.selectedResource && this.selectedContainer;

      //this.value.valid = output;

      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.selectedRepository;
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const output = this.nextCode && selectedLocation && selectedRepository && selectedResource && selectedContainer;
      return !!output;
    },

    getFormData: async function () {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      const selectedRepository = await this.selectedRepository;

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const valid = await this.isFormValid();

      const batchSize = await this.batchSize;

      return {
        absolute_id: {
          barcode: this.nextCode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: selectedResource,
          container: selectedContainer
        },
        batch_size: batchSize,
        valid,
      };
    },

    onInput: async function () {
      const inputState = await this.getFormData();
      this.$emit('input', inputState);
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
      console.log(this);
      console.log(newId);
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
