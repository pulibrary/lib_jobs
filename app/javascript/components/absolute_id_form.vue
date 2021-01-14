
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
        placeholder="Repository ID"
        :list="repositoryOptions"
        :value="repositoryId">
      </input-data-list>

      <input-text
        id="resource_id"
        class="absolute-ids-form--input-field"
        name="resource_id"
        label="Input"
        :hide-label="true"
        placeholder="Resource ID"
        helper="ArchivesSpace Resource"
        :value="resourceId">
      </input-text>
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
      repositoryOptions: []
    }
  },
  mounted: async function () {
    const values = await this.locations;

    this.locationOptions = values.map((location) => {
      return {
        label: location.label,
        value: location.value
      };
    });
  },
  methods: {
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
