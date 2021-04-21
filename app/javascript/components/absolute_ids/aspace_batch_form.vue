<template>
  <form
    :method="method"
    :action="action"
    class="absolute-ids-form"
    v-bind:value="value"
    v-on:input="onInput"
    v-on:submit.prevent="submit"
  >
    <grid-container>
      <grid-item columns="sm-12 lg-3">
        <fieldset class="absolute-ids-form--fields">
          <legend>Barcode</legend>

          <absolute-id-input-text
            id="barcode"
            v-bind:classes="barcodeInputClasses"
            name="barcode"
            label="Barcode"
            :hide-label="true"
            :helper="size > 1 ? 'Starting Barcode' : null"
            :maxlength="barcodeLength"
            v-on:input="onBarcodeInput($event)"
            :disabled="barcodeValid"
            :value="startingBarcode()"
          />

          <div class="lux-input">
            <div class="lux-input-status">
              {{ barcodeStatus }}
            </div>
          </div>

          <input-text
            v-if="size > 1"
            id="terminal_code"
            class="absolute-ids-form--input-field"
            name="terminal_code"
            label="Input"
            :hide-label="true"
            placeholder="Ending Barcode"
            helper="Ending Barcode"
            :disabled="true"
            :value="endingBarcode()"
          />

          <div>
            <button
              data-v-b7851b04
              class="lux-button solid"
              @click.prevent="clearBarcode()"
            >
              Reset
            </button>
          </div>
        </fieldset>
      </grid-item>

      <grid-item columns="sm-12 lg-9">
        <fieldset class="absolute-ids-form--fields">
          <absolute-id-aspace-status
            :action="service.action"
            :token="token"
            service="ArchivesSpace"
          />

          <grid-container>
            <grid-item columns="sm-12 lg-12">
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
                v-model="selectedLocationId"
              />

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
                v-model="selectedContainerProfileId"
              >
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
                display-property="repoCode"
                v-on:input="changeRepositoryId($event)"
              >
              </absolute-id-data-list>
            </grid-item>

            <grid-item columns="sm-12 lg-12">
              <input-text
                id="resource_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedResource,
                  'absolute-ids-form--input-field__invalid':
                    resourceTitle.length > 0 && !validResource,
                  'absolute-ids-form--input-field': true
                }"
                name="resource_id"
                label="Call Number"
                :hide-label="true"
                helper="Call Number"
                :placeholder="resourcePlaceholder"
                :disabled="!selectedRepositoryId || validatingResource"
                v-on:inputblur="onResourceFocusOut($event, resourceTitle)"
                v-model="resourceTitle"
              >
              </input-text>

              <div class="lux-input">
                <div class="lux-input-status">
                  {{ resourceStatus }}
                </div>
              </div>
            </grid-item>
            <grid-item columns="sm-12 lg-9">
              <div>
                <input-checkbox
                  :options="[
                    {
                      name: 'batch_mode',
                      label: 'Reference a range of box numbers',
                      value: batchMode,
                      id: 'checkbox-opt1',
                      checked: batchMode
                    }
                  ]"
                  v-on:change="onChangeBatchMode"
                />
              </div>
            </grid-item>
            <grid-item columns="sm-12 lg-9">
              <input-text
                id="container_id"
                v-bind:class="{
                  'absolute-ids-form--input-field__validated': validatedContainer,
                  'absolute-ids-form--input-field__invalid':
                    containerIndicator.length > 0 && !validContainer,
                  'absolute-ids-form--input-field': true
                }"
                name="container_id"
                :label="batchMode ? 'Starting Box Number' : 'Box Number'"
                :hide-label="true"
                :helper="batchMode ? 'Starting Box Number' : 'Box Number'"
                :placeholder="containerPlaceholder"
                :disabled="
                  !selectedRepositoryId || !resourceTitle || validatingContainer
                "
                v-on:inputblur="onContainerFocusOut($event, containerIndicator)"
                v-model="containerIndicator"
              >
              </input-text>

              <input-text
                v-if="batchMode"
                id="ending_container_id"
                class="absolute-ids-form--input-field"
                name="ending_container_id"
                label="Ending Box Number (Optional)"
                :hide-label="true"
                helper="Ending Box Number"
                :placeholder="endingContainerPlaceholder"
                :disabled="!validContainer"
                v-on:input="onEndingContainerInput($event)"
                v-model="endingContainerIndicator"
              >
              </input-text>

              <div class="lux-input">
                <div class="lux-input-status">
                  {{ containerStatus }}
                </div>
              </div>
            </grid-item>
          </grid-container>
        </fieldset>
      </grid-item>
    </grid-container>
  </form>
</template>

<script>
import BatchFormMixin from "./batch_form_mixin";

import AbsoluteIdASpaceStatus from "./service_status";
import AbsoluteIdInputText from "./input_text";
import AbsoluteIdDataList from "./data_list";

export default {
  name: "AbsoluteIdASpaceForm",
  type: "Element",
  mixins: [BatchFormMixin],
  components: {
    "absolute-id-aspace-status": AbsoluteIdASpaceStatus,
    "absolute-id-input-text": AbsoluteIdInputText,
    "absolute-id-data-list": AbsoluteIdDataList
  },
  props: {
    action: {
      type: String,
      required: true
    },
    method: {
      type: String,
      default: "POST"
    },
    token: {
      type: String,
      default: null
    },
    value: {
      type: Object,
      default: function() {
        return {
          absolute_id: {
            barcode: null,
            location: null,
            container_profile: null,
            repository: null,
            resource: null,
            container: null
          },
          barcodes: [],
          batch_size: 1,
          valid: false
        };
      }
    },
    source: {
      type: String,
      default: "aspace"
    },
    service: {
      type: Object,
      required: true
    },
    barcode: {
      type: String,
      default: ""
    },
    locations: {
      type: Promise,
      required: true
    },
    containerProfiles: {
      type: Promise,
      required: true
    },
    repositories: {
      type: Promise,
      required: true
    },
    batchSize: {
      type: Number,
      default: 1
    }
  },

  computed: {
    /**
     * Placeholder for the location <input> elements
     */
    locationPlaceholder: function() {
      let value = "No locations available";

      if (this.fetchingLocations) {
        value = "Loading...";
      } else if (this.locationOptions.length > 0) {
        value = "Select a location";
      }

      return value;
    },

    /*
     * Placeholder for the repository <input> elements
     */
    repositoryPlaceholder: function() {
      let value = "No repositories available";

      if (this.fetchingLocations) {
        value = "Loading...";
      } else if (this.locationOptions.length > 0) {
        value = "Select a repository";
      }

      return value;
    },

    /**
     * Parse the fetch-retrieved ArchivesSpace Resources
     */
    resources: async function() {
      if (!this.selectedRepositoryId) {
        return [];
      }

      const response = await this.getResources(this.repositoryId);
      const models = response.json();

      return models;
    },

    /*
     * Placeholder for the ContainerProfile <input> elements
     */
    containerProfilePlaceholder: function() {
      let value = "No container profiles available";

      if (this.fetchingRepositories) {
        value = "Loading...";
      } else if (this.repositoryOptions.length > 0) {
        value = "Select a container profile";
      }

      return value;
    },

    /**
     * Parse the fetch-retrieved Container Resources
     */
    containers: async function() {
      if (!this.selectedRepositoryId) {
        return null;
      }

      const response = await this.getContainers(this.selectedRepositoryId);
      const models = response.json();

      return models;
    },

    /*
     * Placeholder for the "Box Number"/Container <input> elements
     */
    containerPlaceholder: function() {
      let value = "No repository selected";

      if (this.selectedResourceId) {
        value = "Enter a box number";
      } else if (this.selectedRepositoryId) {
        value = "No call number specified";
      }

      return value;
    },

    selectedResource: async function() {
      if (!this.selectedResourceId) {
        return null;
      }

      const resolved = await this.resources;
      const model = resolved.find(res => res.id === this.selectedResourceId);
      if (!model) {
        throw `Failed to find the model: ${this.selectedResourceId}`;
      }
      return model;
    },

    selectedContainerProfile: async function() {
      if (!this.selectedContainerProfileId) {
        return null;
      }

      const resolved = await this.containerProfiles;
      const model = resolved.find(
        res => res.id === this.selectedContainerProfileId
      );
      if (!model) {
        throw `Failed to find the model: ${this.selectedContainerProfileId}`;
      }
      return model;
    },

    selectedContainer: async function() {
      if (!this.selectedContainerId) {
        return null;
      }

      const resolved = await this.containers;
      const model = resolved.find(res => res.id === this.selectedContainerId);
      return model;
    },

    selectedLocation: async function() {
      if (!this.selectedLocationId) {
        return null;
      }

      const resolved = await this.locations;
      const model = resolved.find(res => res.id === this.selectedLocationId);
      return model;
    },

    formValid: async function() {
      const selectedLocation = await this.selectedLocation;

      const selectedRepositoryId = await this.selectedRepositoryId;

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

  mounted: async function() {
    const fetchedLocations = await this.locations;
    this.fetchingLocations = false;

    this.locationOptions = fetchedLocations.map(location => {
      const display = location.building;

      let label = location.classification;
      let selected = location.classification;
      if (location.area) {
        label = `${location.area} (${location.classification})`;
        selected = `${location.area} (${location.classification})`;
      } else if (location.building) {
        label = `${location.building} (${location.classification})`;
        selected = `${location.building} (${location.classification})`;
      }

      return {
        id: location.id,
        label: label,
        display: display,
        classification: location.classification,
        building: location.building,
        selected: selected,
        uri: location.uri
      };
    });

    const fetchedContainerProfiles = await this.containerProfiles;
    this.fetchingContainerProfiles = false;

    this.containerProfileOptions = fetchedContainerProfiles.map(
      containerProfile => {
        const display = containerProfile.name;

        let label = containerProfile.name;
        let selected = containerProfile.name;
        if (containerProfile.prefix) {
          label = `${containerProfile.name} (${containerProfile.prefix})`;
          selected = `${containerProfile.name} (${containerProfile.prefix})`;
        }

        return {
          id: containerProfile.id,
          label: label,
          selected: selected,
          uri: containerProfile.uri
        };
      }
    );

    const fetchedRepositories = await this.repositories;
    this.fetchingRepositories = false;

    this.repositoryOptions = fetchedRepositories.map(repository => {
      return {
        id: repository.id,
        label: repository.name,
        selected: repository.name,
        uri: repository.uri,
        repoCode: repository.repo_code
      };
    });
  },

  updated: async function() {
    this.updateValue();

    const base = this.parsedBarcode.slice(0, -1);
    this.updateEndingBarcode(base);

    this.valid = await this.formValid;
  },

  methods: {
    searchResources: async function({ eadId }) {
      const payload = {
        eadId
      };

      let response;
      this.fetchingResources = true;

      try {
        response = await fetch(
          `${this.service.repositories}/${this.selectedRepositoryId}/resources/search`,
          {
            method: "POST",
            mode: "cors",
            cache: "no-cache",
            credentials: "same-origin",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${this.token}`
            },
            redirect: "follow",
            referrerPolicy: "no-referrer",
            body: JSON.stringify(payload)
          }
        );
      } catch (error) {
        console.warn(error);
      }

      this.fetchingResources = false;
      return response;
    },

    searchContainers: async function({ indicator, resourceTitle }) {
      const payload = {
        indicator,
        resourceTitle
      };

      let response;
      this.fetchingContainers = true;

      try {
        response = await fetch(
          `${this.service.repositories}/${this.selectedRepositoryId}/containers/search`,
          {
            method: "POST",
            mode: "cors",
            cache: "no-cache",
            credentials: "same-origin",
            headers: {
              "Content-Type": "application/json",
              Authorization: `Bearer ${this.token}`
            },
            redirect: "follow",
            referrerPolicy: "no-referrer",
            body: JSON.stringify(payload)
          }
        );
      } catch (error) {
        console.warn(error);
      }

      this.fetchingContainers = false;
      return response;
    },

    onResourceFocusOut: async function(event, value) {
      this.validResource = false;
      this.validatedResource = false;

      if (value.length > 0) {
        /*
        const eadId = await this.resourceTitle;

        this.validatingResource = true;

        const response = await this.searchResources({ eadId });
        const resource = await response.json();

        this.validatingResource = false;

        if (resource) {
          this.validResource = true;
          this.validatedResource = true;
        }
        */

        this.validatingResource = false;
        this.validResource = true;
        this.validatedResource = true;
      }
    },

    onContainerFocusOut: async function(event, value) {
      this.validContainer = false;
      this.validatedContainer = false;

      if (value.length > 0) {
        /*
        const resourceTitle = await this.resourceTitle;
        this.validatingContainer = true;

        const response = await this.searchContainers({ indicator: value, resourceTitle });

        this.validatingContainer = false;
        if (!response) {
          return;
        }

        const resource = await response.json();

        if (resource) {
          this.validContainer = true;
          this.validatedContainer = true;
        }
        */

        this.validatingContainer = true;
        this.validatingContainer = false;

        this.validContainer = true;
        this.validatedContainer = true;
      }
    },

    getResources: async function(repositoryId) {
      this.fetchingResources = true;

      const response = await fetch(
        `${this.service.repositories}/${repositoryId}/resources`,
        {
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
        }
      );

      this.fetchingResources = false;
      return response;
    },

    fetchResources: async function(repositoryId) {
      if (!repositoryId) {
        return [];
      }

      const response = await this.getResources(repositoryId);
      const resources = response.json();

      return resources;
    },

    changeRepositoryId: async function(newId) {
      this.repositoryId = newId;

      /*
      const fetchedResources = await this.fetchResources(this.repositoryId);
      this.resourceOptions = fetchedResources.map(resource => {
        return {
          label: resource.title,
          uri: resource.uri,
          id: resource.id
        };
      });
      */

      /*
      const fetchedContainers = await this.fetchContainers(this.repositoryId);
      this.containerOptions = fetchedContainers.map(resource => {
        return {
          label: resource.indicator,
          uri: resource.uri,
          id: resource.id
        };
      });
      */
    },

    getRepositories: async function() {
      this.fetchingRepositories = true;

      const response = await fetch(this.service.repositories, {
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

      this.fetchingRepositories = false;
      return response;
    },

    getLocations: async function() {
      this.fetchingLocations = true;

      try {
        const response = await fetch(this.service.locations, {
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

        this.fetchingLocations = false;
        return response;
      } catch (e) {
        this.fetchingLocations = false;
        return;
      }
    },

    getContainerProfiles: async function() {
      this.fetchingContainerProfiles = true;

      const response = await fetch(this.service.containerProfiles, {
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

      this.fetchingContainerProfiles = false;
      return response;
    },

    getContainers: async function(repositoryId) {
      this.fetchingContainers = true;

      const response = await fetch(
        `${this.service.repositories}/${repositoryId}/containers`,
        {
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
        }
      );

      this.fetchingContainers = false;
      return response;
    },

    fetchContainers: async function(repositoryId) {
      if (!repositoryId) {
        return [];
      }

      const response = await this.getContainers(repositoryId);
      const resources = response.json();

      return resources;
    },

    getSelectedRepository: async function() {
      if (!this.selectedRepositoryId) {
        return null;
      }

      const resolved = await this.repositories;

      const model = resolved.find(
        repo => repo.id.toString() === this.selectedRepositoryId
      );
      return model;
    },

    /**
     * This is needed for the data list
     */
    updateAbsoluteId: async function() {
      if (this.value.absolute_id) {
        if (this.value.absolute_id.location) {
          this.selectedLocationId = this.value.absolute_id.location.id;
        }

        if (this.value.absolute_id.container_profile) {
          this.selectedContainerProfileId = this.value.absolute_id.container_profile.id;
        }

        if (this.value.absolute_id.repository) {
          this.selectedRepositoryId = this.value.absolute_id.repository.id;
        }

        if (this.value.absolute_id.resource) {
          this.selectedResourceId = this.value.absolute_id.resource.id;
        }

        if (this.value.absolute_id.container) {
          this.selectedContainerId = this.value.absolute_id.container.id;
        }
      }
    },

    updateValue: async function() {
      if (this.value) {
        await this.updateAbsoluteId();
      }
    }
  }
};
</script>
