import { createLocalVue, mount } from "@vue/test-utils"
import lux from "lux-design-system"
import AbsoluteIdASpaceStatus from "@/components/absolute_id_aspace_status.vue"

const localVue = createLocalVue()
localVue.use(lux)

describe("AbsoluteIdASpaceStatus", () => {
  let wrapper

  beforeEach(() => {
    fetch.resetMocks()

    wrapper = mount(AbsoluteIdASpaceStatus, {
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
