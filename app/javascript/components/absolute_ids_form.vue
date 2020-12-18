
<template>
  <form method="post" class="absolute-ids-form" v-on:submit.prevent="submit">
    <fieldset class="absolute-ids-form--fields">
      <input-text id="id_prefix" class="absolute-ids-form--input-field" name="prefix" label="Input" :hide-label="true" placeholder="Barcode Prefix" helper="Barcode Prefix" :value="idPrefix"></input-text>
      <input-text id="first_code" class="absolute-ids-form--input-field" name="first_code" label="Input" :hide-label="true" placeholder="Starting Barcode" helper="Starting Barcode" :value="firstCode"></input-text>
      <input-text id="repository_id" class="absolute-ids-form--input-field" name="repository_id" label="Input" :hide-label="true" placeholder="Repository ID" helper="ArchivesSpace Repository ID" :value="repositoryId"></input-text>
      <input-text id="resource_id" class="absolute-ids-form--input-field" name="resource_id" label="Input" :hide-label="true" placeholder="Resource ID" helper="ArchivesSpace Resource ID" :value="resourceId"></input-text>
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
    idPrefix: {
      type: String,
      default: 'A'
    },
    firstCode: {
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
    formData: function () {
      return {
        absolute_id: {
          resource_id: this.resourceId,
          repository_id: this.repositoryId,
          first_code: this.firstCode,
          id_prefix:  this.idPrefix
        }
      };
    }
  },
  methods: {
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
    }
  }
}

</script>
