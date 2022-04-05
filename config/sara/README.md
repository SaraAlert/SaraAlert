# Jurisdiction Configuration

The jurisdictions in `config/sara/jurisdictions.yml` file follow a hierarchical structure. A jurisdiction has a name,
which is the key and some optional values:

- `phone`, `webpage`, `email` - jurisdiction contact information that will only be shown if populated
- `message` - custom jurisdiction message
- `send_digest` - sends assessment reminder to patients if `true`
- `send_close` - sends closed notification to patients who are reporters if `true`,
- `symptoms` - defines the symptoms that the jurisdiction which they belong to would like to track, said jurisdiction will track the symptoms that it specifies **_IN ADDITION TO_** the symptoms specified by all of it's parent jurisdictions
- `children` - the children of a jurisdiction are nested jurisdictions that may have their own properties, which are the same as listed here

## Symptoms

A `symptom` will be identified by it's name, which is the key in the symptom object, a `value`, `type`, `required`, `group` and `threshold_operator`.

### value

The `value` of a symptom defines the threshold of the symptom, this is the value that is considered as
symptomatic for the symptom which it is defining, only symptoms marked as 'required' will be considered when
determining whether or not a patient is symptomatic. For float and integer symptoms, a reported symptom
will be compared using the specified `threshold_operator` to the specified `value` and will be considered as symptomatic. if the result of the comparison is true.

### threshold_operator

Available values for the `threshold_operator` field are `Less Than`, `Less Than Or Equal`,
`Greater Than`, `Greater Than Or Equal`, `Equal` and `Not Equal`.

### type

Available values for the `type` field in a symptom are `FloatSymptom`, `IntegerSymptom`, or `BoolSymptom`.

### group

The group parameter specifies how many symptoms within the same group must pass their threshold values in order to be considered symptomatic. This enables the ability to construct assessments that will be considered symptomatic in the case where N or more of a group of symptoms pass their threshold values. eg: Cough, Fever or any two of Difficulty Breathing, Headache or Vomit. This example would be acheived by setting the Cough and Fever symptoms to be in group 1, and the Difficulty Breathing, Headache and Vomit symptoms to be in group 2. When a group is not specified the default value is 1.
Note: Sub-jurisdictinos can add symptoms to groups, but should not be specifying their own groups.

### required

The `required` field can either take the value `true` of `false`. Only symptoms with `required` set to `true` will be taken into consideration during symptomatic assessment calculation. Additionally, symptoms that have the `required` attribute set to `false` will be omitted from the voice and SMS assessment prompts.

## Translations and Notes

Each symptom supports the inclusion of a more descriptive sentence about what the symptom entails. This, as well as the translations for each symptom name are defined in a locale file under `config/locales`. When adding symptoms, you MUST include entries for these symptoms in each locale!

## Example:

In the configuration below, the USA jurisdiction will have 3 symptoms, these symptoms will apply to the
USA jurisdiction as well as ALL of it's nested children, meaning that all jurisdictions all the way down
to the county-level jurisdictions will inherit these symptoms. State 1 has specified it's own symptoms which
will be added to the symptoms that it inherited from its parent jurisdiction, these symptoms will be applied
to State 1, and the children of State 1 (County 1 and County 2). In other words, a monitoree in State 1,
County 1 or County 2 will be asked about 5 total symptoms as part of their assessments, whereas a monitoree in State 2 or County 3 would only be asked about 3 symptoms. Assessments which have 2 or more of the required group symptoms (Fever) will be considered symptomatic.

```
'USA':
    symptoms:
        # Key is the symptom name as it will appear to the user
        'Cough':
            # The value specified here is the threshold value for the particular symptom
            # values greater than or equal to this value are considered to be symptomatic
            # Useable values for type are [FloatSymptom, IntegerSymptom, or BoolSymptom]
            # The expected threshold value for bool_values should always be true
            value: true
            type: 'BoolSymptom'
            required: true
            threshold_operator: 'Equal'
            group: 1
        'Difficulty Breathing':
            value: true
            type: 'BoolSymptom'
            required: true
            threshold_operator: 'Equal'
            group: 1
        'Fever':
            value: true
            type: 'BoolSymptom'
            notes: 'Feeling feverish or have a measured temperature at or above 100.4°F/38°C'
            required: true
            threshold_operator: 'Equal'
            group: 2
    # Jurisdictions follow a hierarchy, the hierarchy is defined by nesting jurisdictions
    # in the children: field
    children:
        'State 1':
            phone: '+13455555555'
            webpage: 'www.example.com'
            email: 'contact@example.com'
            message: 'This Is a Custom Jurisdiction Message'
            send_digest: true
            send_close: true
            symptoms:
                'Pulse Ox':
                    value: 90
                    threshold_operator: 'Less Than'
                    type: 'FloatSymptom'
                    required: true
                'Other':
                    value: true
                    type: 'BoolSymptom'
                    required: true
                    threshold_operator: 'Equal'
                    group: 1
            children:
                'County 1':
                'County 2':
        'State 2':
            children:
                'County 3':
                'County 4':
```

## Custom Jurisdiction Messages

Jurisdiction messages may be configured in the `jurisdiction_messages.yml` file. The structure of this file closely mimics the structure of the `jurisdictions.yml` file in that jurisdictions are laid out in the same hierarchy with optional `children` and `messages` properties.

- `children` - only children jurisdictions with custom messages need to be included, all jurisdictions without custom messages defined will either use custom messages defined by another jurisdiction up its hierarchy tree if present or use the default message
- `messages` - the contents of this property almost exactly mirrors the contents of the translation files in `config/locales` with the exception that translations for these messages are defined directly under each node representing the message identifier as shown in the example below

```
'USA':
  children:
    'State 1':
      messages:
        assessments:
          html:
            email:
              enrollment:
                info1:
                  eng: |
                    Welcome to symptom monitoring for <a href="http://example.com">State 1 DOH</a>.<br><br>
                    - Lorem<br>
                    - Ipsum
                  spa: |
                    Bienvenido a la monitorización de los síntomas para <a href="http://example.com">El State 1 DOH</a><br><br>
                    - Lorem<br>
                    - Ipsum
          twilio:
            sms:
              prompt:
                intro:
                  eng: |
                    You've been identified by State 1 DOH to be enrolled in Sara Alert to be monitored for COVID symptoms.

                    For privacy and more info, visit saraalert.org.
                  spa: |
                    El State 1 DOH lo identifico para inscribirse en Sara Alert para ser monitoreado por sintomas de COVID.

                    Para privacidad y mas informacion, visite saraalert.org.
```

### Jurisdiction Config Files In This Directory

- `jurisdictions.yml` - Use this jurisdiction config when doing local development or standing up a demo server.

- `performance_jurisdictions.yml` - Use this jurisdiction config when performance testing. It has many more jurisdictions and more closely resembles production.

- `jurisdiction_messages.yml` - Use this custom jurisdiction messages config when doing local development or standing up a demo server.
