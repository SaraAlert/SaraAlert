# Orchestration

## Templates

Templates are meant to represent the superset of available options for configuration. The format of templates should be as follows:

```ruby
TEMPLATE = {
    workflows: {
        workflow1: {
            configuration_feature1: {
                options: {
                    option1: {
                        label: 'Label',
                        property1: {},
                        ...
                    }
                }
            }
            ...
            configuration_featureN: {
                options: {
                    options1: {
                        label: 'Label',
                        options: {
                            sub_option1: {

                            }
                        }
                        ...
                    }
                    ...
                }
            }
        },
        ...
    },
    general: {
        configuration_feature1: {
            ...
        }
        ...
    }
}
```

A template should have 2 properties, `workflows` and `general`. Configurations that go under `general` should be for general UI which is not tied to a specific workflow. Inside of `workflows` should be each supported workflow, indicated by its name which is the key. Each workflow's value should contain the configuration features that define that workflow, also indicated by its name which acts as the key. Each configurable feature should have the required value, `options` which should be the definition of the actual feature's constants in form of a hash or array of values. If the value of `options` is a hash, it can have nested options defined by having another `options` within it.

### Example

In the template written below, defined is a template called `EXAMPLE` which has two workflows, `exposure` and `isolation`. Both have `header_action_buttons` as a configuration option. For the `exposure` workflow, `header_action_buttons` has the `import` option while the `isolation` workflow has just `export`. Both of these options have sub-options: `exposure.import` has `epix`, `saf`, and `sdx` while `isolation.export` has `csv`, `saf`, `purge_eligible`, `all`, and `custom_format`.

```ruby
EXAMPLE = {
    workflows: {
      exposure: {
        header_action_buttons: {
          options: {
            import: { label: 'Import', options: {
              epix: { label: 'Epi-X', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              sdx: { label: 'SDX', workflow_specific: true }
            } }
          }
        }
      },
      isolation: {
        header_action_buttons: {
          options: {
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              purge_eligible: { label: 'Excel Export For Purge-Eligible Monitorees', workflow_specific: false },
              all: { label: 'Excel Export For All Monitorees', workflow_specific: false },
              custom_format: { label: 'Custom Format...', workflow_specific: false }

            } }
          }
        }
      }
    }
```

###

## Playbooks

Templates are implemented in the form of "Playbooks". Playbooks use the templates as a base, indicating an inherited set of options, and add the ability to define what subset of these options should be utilized for a specific instance.

```ruby

NAME = :name_of_playbook

PLAYBOOK =
    label: 'Playbook label',
    workflows: {
      workflow1: { label: 'Workflow 1 Label', base: TEMPLATE[:workflows][:workflow1], custom_options: {
          configuration_feature1: {
            type: 'subset',
            config: {
                set: %i[option1 option2],
                custom_options: {
                    sub_option1: {
                        ...
                    }
                }
            }
          }
      }
      }
    },
    general: {
        ...
    },
    system: {
        ...
    }
}
```

For each workflow, there should be three properties defined:

1. `label`: This is what the workflow should be displayed as.
2. `base`: A reference to the superset of available options for that workflow; it is suggested that this be a hashset from a "Template".
3. `custom_options`: The configurations in respect to the `base`. If there are no custom options wished to be applied (that is you want it to be exactly the same as `base`), this can be set to `{}`.

### Name

This name is used by the orchestrator to select the correct playbook. Additionally, this name will be displayed in the dashboard url (`/dashboard/:playbook/:workflow`).

### Custom Options

Inside `custom_options`, one can define how they would like to pick options from the template.

```ruby
configuration_feature1: {
            label: 'New Label',
            type: 'subset',
            config: {
                set: %i[option1 option2],
                custom_options: {
                    sub_option1: {
                        ...
                    }
                }
            }
          }
```

- `label`: Overwrites the label of the other configuration.
- `type`: One of the following:
  - `'base'`: Returns the whole base configuration. Does not follow nested configurations as it returns from root to leaves.
  - `'all'`: Returns all of the options from the current level of the base configuration, but will still continue to follow the nested configuration.
  - `'subset'`: Selects the given keys from the options, and will also follow the nested configurations
  - `'remove'`: Reject the given keys from the options, and will also follow the nested configurations
  - Default type is `'base'`
- `config`: Configuration for the option. Can have the following two values:
  - `set`: Utilized if `type` is `'subset'` or `'remove'`. This should be set to the list of keys that are taken into consideration for inclusion/exclusion. If `type` is `'all'` or `'base'`, this is ignored.
  - `custom_options`: If the option has sub options, they can be configured in the same manner as in this property.

### Example Usage

Let the template for a specific options be as so:

```ruby
...
    header_action_buttons: {
          options: {
            enroll: { label: 'Enroll New Case' },
            export: { label: 'Export', options: {
              csv: { label: 'Line list CSV', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              purge_eligible: { label: 'Excel Export For Purge-Eligible Monitorees', workflow_specific: false },
              all: { label: 'Excel Export For All Monitorees', workflow_specific: false },
              custom_format: { label: 'Custom Format...', workflow_specific: false }

            } },
            import: { label: 'Import', options: {
              epix: { label: 'Epi-X', workflow_specific: true },
              saf: { label: 'Sara Alert Format', workflow_specific: true },
              sdx: { label: 'SDX', workflow_specific: true }
            } }
          }
        }
...

```

Let the playbook definition for this option then be:

```ruby
...
    header_action_buttons: {
        type: 'all',
        config: {
            custom_options: {
                export: {
                    type: 'subset',
                    config: {
                        set: %i[csv saf]
                    }
                },
                import: {
                    type: 'remove',
                    label: 'New Import Label',
                    config: {
                        set: %i[sdx]
                    }
                }
            }
        }
    }
...
```

In the configuration above, all three options (`enroll`, `export`, `import`) under `header_action_buttons` will be included as the type supplied is `'all'`. Because the type is `'all'` and not `'base'`, we will look to see if any further `custom_options` were supplied. We can see that there are -- `export` has a type `'subset'` and a given `set`; this means for the `export` option under `header_action_buttons` we will only include `csv` and `saf`. On the other hand, `import` has the type `'remove'`, meaning we will excluse that in which is defined in the `set`. In this case we will remove `sdx` from `import`, leaving us with `epix` and `saf`.

What will be returned is the following:

```ruby
{
    options: {
        enroll: { label: 'Enroll New Case' },
        export: { label: 'Export', options: {
            csv: { label: 'Line list CSV', workflow_specific: true },
            saf: { label: 'Sara Alert Format', workflow_specific: true },
        } },
        import: { label: 'New Import Label', options: {
            epix: { label: 'Epi-X', workflow_specific: true },
            saf: { label: 'Sara Alert Format', workflow_specific: true },
        } }
        }
}
```

## Orchestrator

The orchestrator is a set of helper functions that parses the playbooks that are defined in `app/helpers/orchestration/playbooks` to return the desired configurations to the rest of the system (such as the controllers).

To obtain a specific `workflow` configuration option, use the following function:

`workflow_configuration(playbook, workflow, option)`

If `workflow` is set as `nil`, it will look in the `general` section instead.

To obtain system configurations, instead use:

`system_configuration(playbook, option)`

## Notes & Roadmap

At the current moment, the system:

- Supports only 1 playbook at a time, defined by the admin variable `playbook_name` (which can be overwritten by `ENV["ACTIVE_PLAYBOOK"]`)
- Works with the assumption that workflows cannot be renamed from `exposure`, `isolation`, and `global`. They can be relabeled to display a different name, but the base name must remain one of those three, given
- Does not support the addition of features from the playbook; that is, the playbook cannot add features that are not defined in the template that is inherited.
