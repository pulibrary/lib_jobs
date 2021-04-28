import { createLocalVue, mount } from "@vue/test-utils"
import lux from "lux-design-system"
import SessionForm from "@/components/absolute_ids/session_form.vue"

const localVue = createLocalVue()
localVue.use(lux)

describe("SessionForm", () => {
  let wrapper

  beforeEach(() => {
    fetchMock.resetMocks()

    // Locations
    fetchMock.mockIf(/^https?:\/\/localhost.*$/, async (request) => {

      // ArchivesSpace service status
      if (request.url.endsWith("/services/archivesspace")) {
        return {
          headers: {
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: JSON.stringify({
            uri: "https://aspace.university.edu/staff/api"
          })
        }
      // Location resources
      } else if (request.url.endsWith("/locations")) {
        return {
          headers: {
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: JSON.stringify([
            {
              area: "Annex B",
              barcode: null,
              building: "Annex",
              classification: "anxb",
              create_time: "2021-01-22T22:29:46Z",
              external_ids: [],
              floor: null,
              functions: [],
              id: "23640",
              lock_version: 0,
              room: null,
              system_mtime: "2021-01-22T22:29:47Z",
              temporary: null,
              uri: "/locations/23640",
              user_mtime: "2021-01-22T22:29:46Z"
            }
          ])
        }
      // ContainerProfiles resources
      } else if (request.url.endsWith("/container-profiles")) {
        return {
          headers: {
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: JSON.stringify([
            {
              create_time: "2021-01-21T20:10:59Z",
              id: "2",
              lock_version: 873,
              name: "Elephant size box",
              prefix: "P",
              system_mtime: "2021-01-25T05:10:46Z",
              uri: "/container_profiles/2",
              user_mtime: "2021-01-21T20:10:59Z"
            }
          ])
        }
      // Repository resources
      } else if (request.url.endsWith("/repositories")) {
        return {
          headers: {
            'Content-Type': 'application/json; charset=utf-8'
          },
          body: JSON.stringify([
            {
              create_time: "2016-06-27T14:10:41Z",
              id: "3",
              lock_version: 2,
              name: "Public Policy Papers",
              repo_code: "publicpolicy",
              system_mtime: "2021-01-22T22:19:27Z",
              uri: "/repositories/3",
              user_mtime: "2021-01-22T22:19:27Z"
            }
          ])
        }
      } else {
        return {
          status: 404
        }
      }
    })

    wrapper = mount(SessionForm, {
      propsData: {
        action: 'http://localhost/absolute-ids',
        token: 'secret',
        service: {
          action: "http://localhost:3000/services/archivesspace",
          containerProfiles: "http://localhost:3000/absolute-ids/container-profiles",
          locations: "http://localhost:3000/absolute-ids/locations",
          repositories: "http://localhost:3000/absolute-ids/repositories"
        }
      },
      localVue
    })
  })

  it("should mount with an initial form for generating a single AbsoluteID batch for ArchivesSpace", () => {
    const batchForm = wrapper.find(".absolute-ids-batch-form--batch")
    expect(batchForm.text()).toContain("New Batch")

    const form = wrapper.find(".absolute-ids-form")
    expect(form.text()).toContain("ArchivesSpace")
  })
})
