
<template>
  <form method="post" class="absolute-ids-form" v-on:submit.prevent="submit">
    <fieldset>
      <input-text id="repository_id" name="value" label="Input" :hide-label="true" placeholder="ArchivesSpace Repository ID" helper="ID for the related ArchivesSpace Repository"></input-text>
      <input-text id="resource_id" name="value" label="Input" :hide-label="true" placeholder="ArchivesSpace Resource ID" helper="ID for the related ArchivesSpace (Finding Aid) Resource"></input-text>
    </fieldset>
    <button
      data-v-b7851b04
      class="lux-button solid large lux-button"
      v-on:click.stop="submit">Generate a new Absolute ID</button>
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
    }
  },
  methods: {
    submit: async function (event) {
      event.target.disabled = true;
      const response = await this.postData();

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
