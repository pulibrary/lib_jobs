<template>
  <div>
    <grid-container>
      <grid-item columns="lg-12 sm-12">
        <header>{{ header }}</header>
        <form
          class="absolute-ids-sync-form"
          :action="synchronize.action"
          :method="synchronize.method"
        >
          <button
            data-v-b7851b04
            :class="synchronizeButtonClasses"
            :disabled="synchronizing"
            @click.prevent="onSynchronizeSubmit"
          >
            {{ synchronizeButtonTextContent }}
          </button>
        </form>
        <a
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-session--report"
          :href="reportPath"
          >Download Report</a
        >
        <a
          data-v-b7851b04
          class="lux-button solid lux-button absolute-ids-session--xml"
          :href="xmlPath"
          >Export XML Data</a
        >
      </grid-item>
    </grid-container>

    <batch-table
      v-for="batch in session.batches"
      :key="batch.id"
      :token="token"
      :synchronize="synchronize"
      :caption="batch.label"
      :columns="columns"
      :json-data="batch.table_data"
    />
  </div>
</template>

<script>
import BatchTable from "./batch_table";

export default {
  name: "AbsoluteIdSessionTable",
  type: "Element",
  components: {
    "batch-table": BatchTable
  },
  props: {
    header: {
      required: true,
      type: String
    },

    token: {
      required: true,
      type: String
    },

    columns: {
      required: true,
      type: Array
    },

    session: {
      required: true,
      type: Object
    },

    synchronize: {
      type: Object,
      required: false
    },

    reportPath: {
      type: String,
      default: ""
    },

    xmlPath: {
      type: String,
      default: ""
    }
  },
  data() {
    return {
      rows: this.jsonData,
      parsedColumns: [],
      submitted: false
    };
  },
  computed: {
    synchronized: function() {
      return this.synchronize.status == "synchronized";
    },

    synchronizing: function() {
      return this.synchronize.status == "synchronizing";
    },

    synchronizeButtonTextContent: function() {
      let output = "Synchronize";

      if (this.synchronizing || this.submitted) {
        output = "Synchronizing";
      } else if (this.synchronized) {
        output = "Resynchronize";
      }

      return output;
    },

    synchronizeButtonClasses: function() {
      const values = {
        "lux-button": true,
        solid: true,
        "absolute-ids-sync-form__submit": true,
        "absolute-ids-sync-form__submit--finished":
          this.synchronized && !(this.synchronizing || this.submitted),
        "absolute-ids-sync-form__submit--in-progress":
          this.synchronizing || this.submitted
      };

      return values;
    }
  },
  methods: {
    postData: async function() {
      const response = await fetch(this.synchronize.action, {
        method: this.synchronize.method || "POST",
        mode: "cors",
        cache: "no-cache",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.token}`
        },
        redirect: "follow",
        referrerPolicy: "no-referrer"
      });

      return response;
    },
    onSynchronizeSubmit: async function(event) {
      event.target.disabled = true;

      this.submitted = true;
      const response = await this.postData();

      event.target.disabled = false;
      if (response.status === 302) {
        const redirectUrl = response.headers.get("Content-Type");
        window.location.assign(redirectUrl);
      } else {
        window.location.reload();
      }
    }
  }
};
</script>

<style lang="scss" scoped>
@import "../../../../node_modules/lux-design-system/dist/system/system.utils.scss";

.lux-data-table {
  border-collapse: collapse;
  border-spacing: 0;
  border-left: none;
  border-right: none;
  border-bottom: none;

  caption {
    @include stack-space($space-base);
    display: table-caption;
    text-align: left;
    @include responsive-font(
      2vw,
      $font-size-x-large-min,
      $font-size-x-large-max,
      $font-size-x-large
    );
    font-weight: $font-weight-bold;
    font-family: $font-family-text;
    line-height: $line-height-heading;
  }

  thead {
    display: table-header-group;
    vertical-align: middle;
  }

  thead tr {
    background-color: $color-grayscale-lighter;
    color: $color-rich-black;
  }

  th {
    line-height: 22px;
    padding: 20px;
    font-weight: $font-weight-semi-bold;
    font-family: $font-family-text;
    font-size: $font-size-x-small;
    line-height: $line-height-heading;
    text-align: left;
    text-transform: uppercase;
    color: $color-grayscale-darker;
    letter-spacing: 0.5px;
  }

  th,
  td {
    border-bottom: none;
    border-left: none;
    border-right: none;
    border-top: 1px solid darken($color-grayscale-lighter, 10%);
    @include inset-space($space-base);
    overflow: hidden;
  }

  th button {
    padding: 0px;
    font-weight: $font-weight-semi-bold;
    font-family: $font-family-text;
    font-size: $font-size-x-small;
    line-height: $line-height-heading;
    text-align: left;
    text-transform: uppercase;
    color: $color-grayscale-darker;
    letter-spacing: 0.5px;
    display: flex;
    align-items: center;
    margin: 0;

    /deep/ .lux-icon {
      display: initial;
    }
  }

  tbody tr {
    display: table-row;
    vertical-align: inherit;
    background-color: $color-white;
    color: $color-grayscale-darker;

    &:hover {
      background: $color-grayscale-warm-lighter;

      input {
        background: $color-grayscale-warm-lighter;
      }
    }
  }

  tbody {
    background-color: #fff;
  }

  td {
    color: $color-rich-black;
    font-weight: $font-weight-regular;
    font-family: $font-family-text;
    font-size: $font-size-base;
    line-height: 1.2;
    text-align: left;

    input {
      position: relative;
      width: auto;
      cursor: pointer;

      &:hover,
      &:focus,
      &:checked {
        box-shadow: none;
        border: 0;
      }
    }

    input::before,
    input::after {
      position: absolute;
      content: "";

      /*Needed for the line-height to take effect*/
      display: inline-block;
    }

    /*Outer box of the fake checkbox*/
    input::before {
      height: 16px;
      width: 16px;
      background-color: $color-white;
      border: 0;
      border-radius: $border-radius-default;
      box-shadow: inset 0 1px 0 0 rgba($color-rich-black, 0.07),
        0 0 0 1px tint($color-rich-black, 80%);
      left: 0;
      top: 4px;
    }

    /* On mouse-over, add a grey background color */
    input:not([disabled]):hover::before {
      box-shadow: 0 1px 5px 0 rgba($color-rich-black, 0.07),
        0 0 0 1px tint($color-rich-black, 60%);
    }

    input:checked::before {
      transition: box-shadow 0.2s ease;
      background-color: $color-bleu-de-france;
      box-shadow: inset 0 0 0 1px $color-bleu-de-france,
        0 0 0 1px $color-bleu-de-france;
      outline: 0;
    }

    /*Checkmark of the fake checkbox*/
    input::after {
      height: 5px;
      width: 10px;
      border-left: 2px solid $color-white;
      border-bottom: 2px solid $color-white;

      transform: rotate(-45deg);

      left: 3px;
      top: 7px;
    }

    /*Hide the checkmark by default*/
    input[type="checkbox"]::after {
      content: none;
    }

    /*Unhide on the checked state*/
    input[type="checkbox"]:checked::after {
      content: "";
    }

    /*Adding focus styles on the outer-box of the fake checkbox*/
    input[type="checkbox"]:focus::before {
      transition: box-shadow $duration-quickly ease;
      box-shadow: inset 0 0 0 1px $color-bleu-de-france,
        0 0 0 1px $color-bleu-de-france;
    }
  }

  .lux-data-table-currency {
    text-align: right;
  }

  .lux-data-table-currency > span::before {
    content: "$";
  }

  .lux-data-table-number {
    text-align: right;
  }

  .lux-data-table-left {
    text-align: left;
  }

  .lux-data-table-center {
    text-align: center;
  }

  .lux-data-table-right {
    text-align: right;
  }
}
</style>
