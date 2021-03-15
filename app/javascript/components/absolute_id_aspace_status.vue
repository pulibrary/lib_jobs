<template>
  <div class="absolute-ids-form--status">
    <div>{{ service }}</div>
    <tag
      type="tag"
      :tag-items="[
                    {
                      name: textContent,
                      color: tagColor,
                      style: 'pill'
                    }
                  ]"
      horizontal="start"
      size="small"
    />
  </div>
</template>

<script>
export default {
  name: 'AbsoluteIdServiceStatus',
  type: 'Element',
  props: {
    method: {
      type: String,
      default: 'GET'
    },
    action: {
      type: String,
      required: true
    },
    token: {
      type: String,
      required: true
    },
    service: {
      type: String,
      required: true
    }
  },
  data: function () {
    return {
      status: 'CONNECTING'
    }
  },
  computed: {
    tagColor: function () {
      let output = 'red';

      switch (this.status) {
        case 'CONNECTING':
          output = 'yellow';
          break;
        case 'ONLINE':
          output = 'green';
          break;
      }

      return output;
    },

    textContent: function () {
      let output = 'Offline';

      switch (this.status) {
        case 'CONNECTING':
          output = 'Connecting';
          break;
        case 'ONLINE':
          output = 'Online';
          break;
      }

      return output;
    }
  },

  mounted: async function () {
    this.$nextTick(async function () {
      const service = await this.getService();

      this.status = 'OFFLINE';
      if (service) {
        this.status = 'ONLINE';
      }
    })
  },

  methods: {
    fetchService: async function () {
      let response = null;

      try {
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
          referrerPolicy: 'no-referrer'
        });

        return response;
      } catch (error) {
        console.warn(`Failed to request the status for the service ${this.service}: ${error}`);
      }

      return;
    },

    getService: async function () {
      let service = null;
      let response;

      response = await this.fetchService();
      service = await response.json();

      return service;
    }
  }
}
</script>
