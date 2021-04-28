import { createLocalVue, mount } from "@vue/test-utils"
import lux from "lux-design-system"
import ServiceStatus from "@/components/absolute_ids/service_status.vue"

const localVue = createLocalVue()
localVue.use(lux)

describe("ServiceStatus", () => {
  let wrapper

  beforeEach(() => {
    fetch.resetMocks()

    wrapper = mount(ServiceStatus, {
      propsData: {
        action: '/services/archivesspace',
        token: 'secret',
        service: 'ArchivesSpace'
      },
      localVue
    })

    fetch.mockResponseOnce(
      JSON.stringify({
        uri: "https://aspace.university.edu/staff/api"
      })
    )
  })

  it("should mount with an initial status of 'Connecting'", () => {
    const el = wrapper.find(".lux-tag")
    expect(el.text()).toBe("Connecting")
  })
})
