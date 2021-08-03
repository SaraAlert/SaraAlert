# Orchestration

## Templates

Templates represent the superset of available configuration options. It is represented as a Ruby hash with the following structure:

```ruby
TEMPLATE = {
    workflows: {
        workflow1: {
            configuration_feature1: {
                options: {
                    option1: {
                        label: 'LabelValueHere',
                        property1: {},
                        ...
                    }
                }
            }
            ...
            configuration_featureN: {
                options: {
                    options1: {
                        label: 'LabelValueHere',
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

A template has 2 required properties: `workflows` and `general`. Configurations that go under `general` are for general UI that is not tied to a specific workflow. Inside of `workflows` is a definition for each supported workflow, indicated by its name which is the key. Each workflow's value contains the configuration features that define that workflow, also indicated by its name which acts as the key. Each configurable feature should have the required object, `options` which should be the definition of the actual feature's constants in form of a hash or array of values. If the value of `options` is a hash, it can have nested options defined by having another `options` within it.

### Example

The example below presents a templated named `EXAMPLE`. This template defines two workflows: `exposure` and `isolation`. Both offer the configurable option, `header_action_buttons`. This option conrols which buttons are presented on the monitoring dashboard. In the example, the `import` option is configured for the `exposure` workflow while just the `export` option is configured for the `isolation` workflow. Both of these options specify sub-options, which are manifest as drop-down menu options: `exposure[import]` has `epix`, `saf`, and `sdx` while `isolation[export]` has `csv`, `saf`, `purge_eligible`, `all`, and `custom_format`.

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

Templates are implemented in the form of "Playbooks". Playbooks use the templates as a base, indicating an inherited set of options, and define what subset of these options should be utilized for a specific instance. A playbook is defined within a Ruby module that contains the two variables, `NAME`, and `PLAYBOOK`.

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

The value of the `NAME` variable is expected to be a Ruby symbol and is used by the orchestrator to select the correct playbook. Additionally, this name will be used along with the active workflow name as part of the dashboard url (`/dashboard/playbook_name/workflow_name`).

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

In the configuration above, all three options (`enroll`, `export`, `import`) under `header_action_buttons` will be included as the type supplied is `'all'`. Because the type is `'all'` and not `'base'`, we will look to see if any further `custom_options` were supplied. We can see that there are -- `export` has a type `'subset'` and a given `set`; this means for the `export` option under `header_action_buttons` we will only include `csv` and `saf`. On the other hand, `import` has the type `'remove'`, meaning we will exclude that which is defined in the `set`. In this case we will remove `sdx` from `import`, leaving us with `epix` and `saf`.

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

The orchestrator is a set of helper functions that parse the playbooks that are found in `app/helpers/orchestration/playbooks`. These helper functions are accessed by the rest of the system (such as the controllers) to determined the desired configuration.

To obtain a specific `workflow` configuration option, use the following function:

`workflow_configuration(playbook, workflow, option)`

If `workflow` is set as `nil`, it will look in the `general` section instead.

To obtain system configurations, use:

`system_configuration(playbook, option)`

## Constraints

The following constraints should be considered when defining a new playbook.

- Only 1 playbook may be active at a time. The playbook in use is defined in `config/sara.yml` by the admin variable, `playbook_name`. This can be overwritten by `ENV["ACTIVE_PLAYBOOK"]`)
- The object names used for workflows must be a combination of `exposure`, `isolation`, and `global`. The values used for the label attributie can be changed in order to display a different name on the GUi, but the base name must be one of those three.
- A playbook configuration cannot be used to add features that are not available (i.e., defined) in the template that is inherited.
