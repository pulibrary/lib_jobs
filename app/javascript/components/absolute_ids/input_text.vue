<template>
  <component :is="wrapper" class="lux-input" :class="containerClasses()">
    <label v-if="label" :for="id" :class="{ 'lux-hidden': hideLabel }">{{
      label
    }}</label>
    <div class="lux-input" :class="inputClasses()">
      <input
        v-if="type !== 'textarea'"
        autocomplete="off"
        :name="name"
        :value="value"
        :id="id"
        :readonly="readonly"
        :disabled="disabled"
        :required="required"
        :type="type"
        :maxlength="maxlength"
        :hover="hover"
        :placeholder="placeholder"
        :errormessage="errormessage"
        :class="['lux-input', { 'lux-input-error': hasError }]"
        v-on:input="$emit('input', $event.target.value)"
        @blur="inputblur($event)"
        v-focus="focused"
        @focus="focused = true"
      />

      <textarea
        v-else
        autocomplete="off"
        :name="name"
        :id="id"
        :disabled="disabled"
        :readonly="readonly"
        :required="required"
        :rows="rows"
        :maxlength="maxlength"
        :hover="hover"
        v-focus="focused"
        @focus="focused = true"
        :value="value"
        :placeholder="placeholder"
        :errormessage="errormessage"
        :class="[
          'lux-input',
          { 'lux-input-error': hasError },
          { 'lux-input-expand': width === 'expand' }
        ]"
        v-on:input="$emit('input', $event.target.value)"
        @blur="inputblur($event)"
      />

      <div v-if="icon" class="append-icon">
        <lux-icon-base width="24" height="24">
          <lux-icon-alert v-if="icon === 'alert'"></lux-icon-alert>
          <lux-icon-approved v-if="icon === 'approved'"></lux-icon-approved>
          <lux-icon-denied v-if="icon === 'denied'"></lux-icon-denied>
        </lux-icon-base>
      </div>
    </div>

    <div role="alert" class="lux-error" v-if="errormessage">
      {{ errormessage }}
    </div>
    <div class="lux-helper" v-if="helper">{{ helper }}</div>
  </component>
</template>

<script>
import { mixin as focusMixin } from "vue-focus";
/**
 * Form Inputs are used to allow users to provide text input when the expected
 * input is short. Form Input has a range of options and supports several text
 * formats including numbers. For longer input, use the `FormTextarea` element.
 */
export default {
  name: "AbsoluteIdInputText",
  type: "Element",
  mixins: [focusMixin],
  computed: {
    hasError() {
      return this.errormessage.length;
    }
  },
  data: function() {
    return {
      focused: false
    };
  },
  props: {
    classes: {
      type: Object,
      default: function() {
        return {};
      }
    },
    /**
     * The type of the form input field.
     * `text, number, email`
     */
    type: {
      type: String,
      default: "text",
      validator: value => {
        return value.match(/(text|number|email|textarea)/);
      }
    },
    /**
     * Text value of the form input field.
     */
    value: {
      type: [String, Number],
      default: ""
    },
    /**
     * The placeholder value for the form input field.
     */
    placeholder: {
      type: String,
      default: ""
    },
    /**
     * The label of the form input field.
     */
    label: {
      type: String,
      default: ""
    },
    /**
     * Visually hides the label of the form input field.
     */
    hideLabel: {
      type: Boolean,
      default: false
    },
    /**
     * The validation message a user should get.
     */
    errormessage: {
      type: String,
      default: ""
    },
    /**
     * The helper text a user should get.
     */
    helper: {
      type: String,
      default: ""
    },
    /**
     * The html element name used for the wrapper.
     * `div, section`
     */
    wrapper: {
      type: String,
      default: "div",
      validator: value => {
        return value.match(/(div|section)/);
      }
    },
    /**
     * Unique identifier of the form input field.
     */
    id: {
      type: String,
      default: "",
      required: true
    },
    /**
     * The name attribute for the form input field.
     */
    name: {
      type: String,
      default: "",
      required: true
    },
    /**
     * The width of the form input field.
     * `auto, expand`
     */
    width: {
      type: String,
      default: "expand",
      validator: value => {
        return value.match(/(auto|expand)/);
      }
    },
    /**
     * Sets the size of the input area `small, medium, large`
     */
    size: {
      type: String,
      default: "medium",
      validator: value => {
        return value.match(/(small|medium|large)/);
      }
    },
    /**
     * The number of visible text lines for textarea.
     */
    rows: {
      type: String,
      default: "5"
    },
    /**
     * The maximum number of characters that the user can enter in textarea.
     */
    maxlength: {
      type: Number,
      default: 256
    },

    disabled: {
      type: Boolean,
      default: false
    },

    readonly: {
      type: Boolean,
      default: false
    },

    required: {
      type: Boolean,
      default: false
    },

    hover: {
      type: Boolean,
      default: false
    },

    icon: {
      type: String,
      default: ""
    }
  },
  methods: {
    inputClasses() {
      const output = Object.assign(
        {},
        {
          "lux-input-expand": this.width === "expand",
          "lux-input-field": true,
          disabled: this.disabled,
          size: this.size
        }
      );

      const size = this.size;
      output[size] = size;

      return output;
    },

    containerClasses() {
      return Object.assign({}, this.classes, {
        "lux-has-icon": this.icon
      });
    },

    inputblur(value) {
      this.$emit("inputblur", value);
      this.focused = false;
    }
  }
};
</script>
