---
name: Ruby upgrade
about: Upgrading the version of ruby
title: 'Upgrade to ruby [INSERT VERSION NUMBER HERE]'
labels: maintenance
assignees: ''

---

- [ ] Add the new ruby version to CircleCI
- [ ] Fix any failing tests or dependency issues caused by ruby upgrade
- [ ] Make sure that aspace_helpers is compatible with the new ruby version, since it is on the same box.
- [ ] Provision staging box to use the new ruby version
- [ ] Deploy code that works with the new ruby version to staging
- [ ] Test on staging box with the new ruby version
- [ ] Provision production box to use the new ruby version
- [ ] Deploy to prod, confirm working on the new ruby version
- [ ] Update this issue template with anything we need to keep in mind for the next upgrade
