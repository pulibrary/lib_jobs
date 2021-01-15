<template>
  <form method="post" class="absolute-ids-form" v-on:submit.prevent="submit">
    <fieldset class="absolute-ids-form--fields">
      <input-data-list
        id="location"
        class="absolute-ids-form--input-field"
        name="location"
        label="Location"
        :hide-label="true"
        helper="Location Code"
        :placeholder="placeholderLocation"
        :list="locationOptions"
        :value="nextLocation">
      </input-data-list>

      <input-text
        id="next_prefix"
        class="absolute-ids-form--input-field"
        name="prefix"
        label="Input"
        :hide-label="true"
        placeholder="Prefix"
        helper="Prefix"
        :value="nextPrefix">
      </input-text>

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

      <input-data-list
        id="repository_id"
        class="absolute-ids-form--input-field"
        name="repository_id"
        label="Repository"
        :hide-label="true"
        helper="ArchivesSpace Repository"
        :placeholder="repositoryPlaceholder"
        :disabled="fetchingRepositories"
        :list="repositoryOptions"
        :value="repositoryId"
        @input="changeRepositoryId">
      </input-data-list>

      <input-data-list
        id="resource_id"
        class="absolute-ids-form--input-field"
        name="resource_id"
        label="Resource"
        :hide-label="true"
        helper="ArchivesSpace Resource"
        :placeholder="resourcePlaceholder"
        :disabled="resourceOptions.length < 1"
        :list="resourceOptions"
        :value="resourceId">
      </input-data-list>
    </fieldset>
    <button
      data-v-b7851b04
      class="lux-button solid large lux-button absolute-ids-form--submit">Generate</button>
  </form>
</template>

<script>

export default {
  name: 'AbsoluteIdsForm',
  status: 'ready',
  release: '1.0.0',
  type: 'Element',
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
    placeholderLocation: {
      type: String,
      default: 'Example: cotsen'
    },
    nextLocation: {
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
    },
    repositoryId: {
      type: String,
      default: null
    },
    resourceId: {
      type: String,
      default: null
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
      if (!this.repositoryId) {
        return [];
      }

      const response = await this.getResources();
      const resources = response.json();

      return resources;
    },

    resourcePlaceholder: function () {
      let value = 'No repository selected';

      if (this.fetchingResources) {
        value = 'Loading...';
      } else if (this.repositoryId && this.resourceOptions.length < 1) {
        value = 'No resources available';
      } else if (this.resourceOptions.length > 1) {
        value = 'Select a resource';
      }

      return value;
    },

    formData: function () {
      return {
        absolute_id: {
          resource_id: this.resourceId,
          repository_id: this.repositoryId,
          value: this.nextCode,
          prefix:  this.nextPrefix,
          location: this.nextLocation
        }
      };
    }
  },
  data: function () {
    return {
      locationOptions: [],
      repositoryOptions: [],
      resourceOptions: [],
      fetchingRepositories: false,
      fetchingResources: false
    }
  },
  mounted: async function () {
    const fetchedLocations = await this.locations;

    this.locationOptions = fetchedLocations.map((location) => {
      return {
        label: location.label,
        value: location.value
      };
    });

    const fetchedRepositories = await this.repositories;
    this.repositoryOptions = fetchedRepositories.map((repository) => {
      return {
        label: repository.name,
        value: repository.id
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

    changeRepositoryId: async function (repositoryId) {
      const fetchedResources = await this.fetchResources(repositoryId);
      this.resourceOptions = fetchedResources.map((resource) => {
        return {
          label: resource.title,
          value: resource.id
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
      event.target.disabled = true;
      const response = await this.postData(this.formData);

      event.target.disabled = false;
      if (response.status == 301) {
        const redirectUrl = response.headers.get('Content-Type');
        window.location.assign(redirectUrl);
      } else {
        window.location.reload();
      }
    },
  }
}

</script>
