defmodule Taglet.ModelManager do
  defmacro __using__(model_context) do
    context = Atom.to_string(model_context)
    singularized_context = Inflex.singularize(context)

    quote do
      def unquote(:"add_#{singularized_context}")(struct, tag) do
        Taglet.add(struct, tag, unquote(context))
      end

      def unquote(:"#{context}_list")(struct) do
        Taglet.tag_list(struct, unquote(context))
      end
    end
  end
end
