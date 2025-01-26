# Translation Key Naming Convention

## General Rules

1. Use lowercase letters and underscores
2. Follow format: `[feature]_[context]_[type]_[description]`
3. Keep keys concise but descriptive
4. Use consistent terminology across all translations

## Key Structure

### Basic Format
```
[feature]_[description]
[feature]_[context]_[description]
[feature]_[context]_[type]_[description]
```

### Components

1. Feature (Required)
   - Represents the main feature/module (e.g., discover, library, settings)
   - Always comes first in the key
   - Examples: `discover_`, `library_`, `settings_`, `timelines_`

2. Context (Optional)
   - Describes where the string appears
   - Examples: `search_`, `profile_`, `status_`

3. Type (Optional)
   - Describes the type of UI element
   - Common types:
     - `title`: Section or page titles
     - `label`: Labels for fields or items
     - `button`: Button text
     - `description`: Longer descriptive text
     - `error`: Error messages
     - `format`: String format templates

4. Description
   - Brief description of the content
   - Use verbs for actions
   - Use nouns for labels

## Examples

```
# Simple keys
library_title
settings_title

# With context
discover_search_title
discover_search_prompt

# With type
timelines_status_error_title
timelines_profile_not_found_description

# Action related
mark_save_button
mark_delete_button

# Format strings
library_empty_description  # Contains %@ placeholder
```

## Special Cases

1. Feature-specific Patterns
   - Shelf types: `shelf_type_[action]_[category]_[label]`
   - Mark actions: `mark_[action]_[type]`

2. Reusable Components
   - Use consistent prefixes for similar components
   - Example: All timeline-related keys start with `timelines_`

## Best Practices

1. Consistency
   - Use same pattern for similar strings
   - Maintain consistent terminology

2. Clarity
   - Keys should be self-descriptive
   - Avoid abbreviations unless widely understood

3. Maintainability
   - Group related strings together
   - Use comments for complex strings or those requiring context

4. Localization Support
   - Include appropriate context in comments
   - Consider string formatting needs for different languages
