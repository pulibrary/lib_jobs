<template>
  <form method="post" class="absolute-ids-form" v-on:submit.prevent="submit">

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
        :value="selectedLocationId"
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
        :value="selectedContainerProfileId"
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
        :value="selectedRepositoryId"
        v-model="selectedRepositoryId"
        v-on:change="changeRepositoryId($event)">
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
        :value="selectedResourceId"
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
        :value="selectedContainerId"
        v-model="selectedContainerId">
      </absolute-id-data-list>
    </fieldset>

    <button
      data-v-b7851b04
      class="lux-button solid large lux-button absolute-ids-form--submit"
      :disabled="!formValid">Generate</button>
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
    nextPrefix: {
      type: String,
      default: 'A'
    },
    nextCode: {
      type: String,
      default: '000000000000'
    }
  },
  data: function () {
    return {
      selectedLocationId: null,
      selectedContainerProfileId: null,
      selectedRepositoryId: null,
      selectedResourceId: null,
      selectedContainerId: null,

      locationOptions: [],
      fetchingLocations: false,

      repositoryOptions: [],
      fetchingRepositories: false,

      resourceOptions: [],
      fetchingResources: false,

      containerProfileOptions: [],
      fetchingContainerProfiles: false,

      containerOptions: [],
      fetchingContainers: false
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

    //selectedRepositoryUri: async function () {
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
      return model;
    },

    selectedContainer: async function () {
      if (!this.selectedContainerId) {
        return null;
      }

      const resolved = await this.containers;
      console.log(resolved);
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
      const selectedRepository = await this.selectedRepository;

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      return {
        absolute_id: {
          barcode: this.nextCode,
          location_uri: selectedLocation,
          repository_uri: selectedRepository,
          resource_uri: selectedResource,
          container_uri: selectedContainer,
          container_profile: selectedContainerProfile
        }
      };
    },

    formValid: function () {
      return this.selectedResourceId && this.selectedRepositoryId && this.nextCode && this.nextPrefix && this.selectedLocationId;
    }
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
