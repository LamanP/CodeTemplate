# Template files
Template files consists of sections. Each section is introduced by a line that starts with a hash character (#):

#_sectiontype_[:_args_]...

The section type is followed by zero or more arguments, which always start with a colon (:). The number of arguments depend on the section type.

The following section types exist:

- _#parameter:name:type[:default]_ - Defines a parameter that is used for substitution in the code template. For example, if the template is used for a class, it will be someting like `#parameter:class`. In the code template, you will use `${class}` wherever you want to use the class name. For example (Delphi): `${class} = class(TObject)`. When using the template, `${class}` will be substituted by the actual classname you fill in for the parameter.
- _#code:caption_ - This introduces a code snippet. The snippet will consist of all the lines following it, until a new # line is encountered. The program will put all snippets on a tab of their own, using the caption to identify the tab.
- _#persist:keypath_ : This declares a key path for persisting parameter values. The parameter following this declaration will be persisted with the path. For example, if the key path is `delphi.class.name`, the value of the next parameter in the template will be persisted under this key. So next time a parameter with the same key path is loaded from the same or another template, it will get the persisted value. This avoids having to repeatedly having to fill in the same class name over again.
- _#persistkeys:file_ - Declares a relative filespec (relative to the location of the template) that defines the keys paths that are allowed. This intents to keep the key paths consistent.

# Key path files
a key path file declares all allowed keys in the following format:

- _#key:value_- Declares a key
- _#maxhistory:n_ : Declares the maximum number of used values to remember per key.