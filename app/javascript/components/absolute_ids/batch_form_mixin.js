import AbsoluteIdASpaceStatus from "./service_status";
import AbsoluteIdInputText from "./input_text";
import AbsoluteIdDataList from "./data_list";

export default {
  data: function() {
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

      resourceTitle,
      containerIndicator,

      // Locations
      locationOptions: [],
      fetchingLocations: true,

      // ContainerProfiles
      containerProfileOptions: [],
      fetchingContainerProfiles: true,

      // Repositories
      repositoryOptions: [],
      fetchingRepositories: true,

      // ArchivesSpace Resources
      resourceOptions: [],
      fetchingResources: false,
      validResource: false,
      validatedResource: false,
      validatingResource: false,

      // Containers
      containerOptions: [],
      fetchingContainers: false,
      validContainer: false,
      validatedContainer: false,
      validatingContainer: false,

      // Barcode
      barcodeLength: 13,
      barcodeValid: false,
      barcodeValidated: false,
      barcodeValidating: false,
      parsedBarcode: this.barcode,
      parsedEndingBarcode: "",
      batchMode: true,

      repositoryId: null,
      barcodes: [],
      size: this.batchSize,

      endingContainerIndicator: "",

      valid: false
    };
  },

  computed: {
    /**
     * Source radio button
     */
    sourceLegend: function() {
      let output;

      if (this.source == "aspace") {
        output = "ArchivesSpace";
      } else if (this.source == "marc") {
        output = "MARC";
      }

      return output;
    },

    /**
     * CSS classes for barcode <input> elements
     */
    barcodeInputClasses: function() {
      const barcodeValidated = this.barcodeValidated;
      const barcode = this.parsedBarcode;
      const barcodeValid = this.barcodeValid;

      const output = {
        "absolute-ids-form--input-field__validated": barcodeValidated,
        "absolute-ids-form--input-field__invalid": barcode.length > 0 && !barcodeValid,
        "absolute-ids-form--input-field": true
      };

      return output;
    },

    /**
     * Barcode status indicator
     */
    barcodeStatus: function() {
      if (this.barcodeValid) {
        return "Barcode is valid";
      } else if (this.barcodeValidating) {
        return "Validating barcode...";
      } else if (this.parsedBarcode.length < 13) {
        return "Please enter a unique 13-digit barcode";
      } else {
        return "This barcode has already been used. Please enter a unique barcode.";
      }
    },

    /**
     * Call number/Resource status indicator
     */
    resourceStatus: function() {
      if (this.validResource) {
        return "Call number is valid";
      } else if (this.validatingResource) {
        return "Validating call number...";
      } else if (this.selectedRepositoryId) {
        return "Please enter a call number";
      } else {
        return "";
      }
    },

    /**
     * Box number/Container status indicator
     */
    containerStatus: function() {
      if (this.validContainer) {
        return "Box number is valid";
      } else if (this.validatingContainer) {
        return "Validating box number...";
      } else if (this.resourceTitle && this.validResource) {
        return "Please enter a box number";
      } else {
        return "";
      }
    },

    endingContainerPlaceholder: function() {
      if (this.validContainer) {
        return this.containerIndicator;
      } else {
        return "No call number specified";
      }
    },

    resourcePlaceholder: function() {
      let value = "No repository specified";

      if (this.selectedRepositoryId) {
        value = "Enter a call number";
      }

      return value;
    },

    containerPlaceholder: function() {
      let value = "No call number specified";

      if (this.selectedResourceId) {
        value = "Enter a box number";
      } else if (this.selectedRepositoryId) {
        value = "No call number specified";
      }

      return value;
    },

    formData: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;

      const selectedRepository = await this.getSelectedRepository();

      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const valid = await this.formValid;

      return {
        absolute_id: {
          source: this.source,
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: this.resourceTitle,
          container: this.containerIndicator
        },
        valid
      };
    },

    formValid: async function() {
      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.getSelectedRepository();

      const output =
        this.parsedBarcode &&
        selectedLocation &&
        selectedRepository &&
        this.resourceTitle &&
        this.containerIndicator;
      return !!output;
    }
  },

  updated: async function() {
    const base = this.parsedBarcode.slice(0, -1);
    this.updateEndingBarcode(base);

    this.valid = await this.formValid;
  },

  methods: {
    onChangeBatchMode: async function(updated) {
      this.batchMode = updated;
    },

    /**
     * Barcode Methods
     */
    startingBarcode: function() {
      return this.parsedBarcode;
    },

    clearBarcode: function() {
      this.parsedBarcode = "";
      this.barcodeValid = false;
      this.barcodeValidated = false;
    },

    endingBarcode: function() {
      return this.parsedEndingBarcode;
    },

    generateChecksum: function(base) {
      const padded = `${base}0`;
      const len = padded.length;
      const parity = len % 2;
      let sum = 0;

      for (let i = len - 1; i >= 0; i--) {
        let d = parseInt(padded.charAt(i));
        if (i % 2 == parity) {
          d *= 2;
        }
        if (d > 9) {
          d -= 9;
        }
        sum += d;
      }

      const remainder = sum % 10;
      return remainder == 0 ? 0 : 10 - remainder;
    },

    updateBarcode: function(value) {
      if (value.length < 13) {
        this.barcodeLength = 13;
        this.barcodeValid = false;
      } else if (value.length == 13) {
        const checksum = this.generateChecksum(value);
        this.barcodeLength = 14;
        this.barcodeValid = true;

        this.parsedBarcode = `${value}${checksum}`;
      }
    },

    updateEndingBarcode: function(value) {
      if (value.length < 13 || this.size < 2) {
        return;
      }

      const parsed = Number.parseInt(value);
      const incremented = parsed + this.size - 1;

      const encoded = incremented.toString();
      const formatted = encoded.padStart(13, 0);
      const checksum = this.generateChecksum(formatted);

      this.parsedEndingBarcode = `${formatted}${checksum}`;
    },

    updateBarcodes: function() {
      if (this.size > 0) {
        for (const i of Array(this.size).keys()) {
          const base = this.parsedBarcode.slice(0, 13);
          const value = Number.parseInt(base) + i;
          const encoded = `${value}`;
          const incremented = encoded.padStart(13, 0);
          const checksum = this.generateChecksum(incremented);
          const newBarcode = `${incremented}${checksum}`;

          this.$set(this.barcodes, i, newBarcode);
        }
      }
    },

    getBarcode: async function(barcode) {
      let response;
      let resource;
      this.barcodeValidating = true;

      try {
        response = await fetch(`${this.service.barcodes}/${barcode}`, {
          method: "GET",
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
        resource = response.json();
      } catch (error) {
        console.warn(error);
      }

      this.barcodeValidating = false;
      return resource;
    },

    validateBarcode: async function() {
      const barcode = await this.parsedBarcode;
      if (barcode.length < 13) {
        return false;
      }

      const resource = await this.getBarcode(barcode);

      return !resource;
    },

    onBarcodeInput: async function(value) {
      this.updateBarcode(value);

      // Disabling this due to performance issues
      //this.barcodeValid = await this.validateBarcode();
      this.barcodeValid = true;
      this.barcodeValidated = this.barcodeValid;
      if (!this.barcodeValid) {
        return;
      }

      this.updateEndingBarcode(value);
      this.updateBarcodes();
    },

    onResourceFocusOut: async function(event, value) {
      this.validatingResource = false;
      this.validResource = true;
      this.validatedResource = true;
    },

    onContainerFocusOut: async function(event, value) {
      this.validatingContainer = true;
      this.validatingContainer = false;

      this.validContainer = true;
      this.validatedContainer = true;
    },

    onEndingContainerInput: function(value) {
      const payload = {
        start: this.containerIndicator,
        end: value
      };
      const firstIndex = Number.parseInt(this.containerIndicator);
      const lastIndex = Number.parseInt(value);
      this.size = lastIndex - firstIndex + 1;
      this.updateBarcodes();

      this.$emit("input-size", payload);
    },

    /**
     * Form validation
     */
    isFormValid: async function() {
      const selectedLocation = await this.selectedLocation;
      const selectedRepository = await this.getSelectedRepository();
      const selectedResource = await this.selectedResource;
      const selectedContainer = await this.selectedContainer;

      const output =
        this.parsedBarcode &&
        selectedLocation &&
        selectedRepository &&
        this.resourceTitle &&
        this.containerIndicator;
      return !!output;
    },

    getFormData: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedContainerProfile = await this.selectedContainerProfile;
      const selectedRepository = await this.getSelectedRepository();

      const resourceTitle = await this.resourceTitle;
      const containerIndicator = await this.containerIndicator;

      const valid = await this.isFormValid();

      return {
        absolute_id: {
          barcode: this.parsedBarcode,
          location: selectedLocation,
          container_profile: selectedContainerProfile,
          repository: selectedRepository,
          resource: resourceTitle,
          container: containerIndicator
        },
        barcodes: this.barcodes,
        batch_size: this.batchSize,
        source: this.source,
        valid
      };
    },

    onInput: async function() {
      const inputState = await this.getFormData();
      this.$emit("input", inputState);
    },

    resourceClasses: async function() {
      const classes = ["absolute-ids-form--input-field"];

      const validatedResource = await this.validatedResource;
      const validResource = await this.validResource;
      const resourceTitle = await this.resourceTitle;

      if (validatedResource) {
        classes.push("absolute-ids-form--input-field__validated");
      } else if (resourceTitle.length > 0 && !validResource) {
        classes.push("absolute-ids-form--input-field__invalid");
      }

      return classes.join(" ");
    },

    containerClasses: async function() {
      const classes = ["absolute-ids-form--input-field"];

      const validatedContainer = await this.validatedContainer;
      const validContainer = await this.validContainer;
      const containerIndicator = await this.containerIndicator;

      if (validatedContainer) {
        classes.push("absolute-ids-form--input-field__validated");
      } else if (containerIndicator.length > 0 && !validContainer) {
        classes.push("absolute-ids-form--input-field__invalid");
      }

      return classes.join(" ");
    }
  }
};
