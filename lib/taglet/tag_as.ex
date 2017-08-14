defmodule Taglet.TagAs do
  defmacro __using__(model_context) do
    context = Atom.to_string(model_context)
    singularized_context = Inflex.singularize(context)

    quote do
      @before_compile unquote(__MODULE__)
      Module.register_attribute __MODULE__, :contexts, accumulate: true
      @contexts unquote(context)

      def unquote(:"add_#{singularized_context}")(struct, tag) when is_binary(tag) do
        Taglet.add(struct, tag, unquote(context), [])
      end
      def unquote(:"add_#{singularized_context}")(struct, tag, opts) do
        Taglet.add(struct, tag, unquote(context), opts)
      end

      def unquote(:"add_#{context}")(struct, tags) when not is_list(struct) do
        Taglet.add(struct, tags, unquote(context), [])
      end
      def unquote(:"add_#{context}")(struct, tags, opts) do
        Taglet.add(struct, tags, unquote(context), opts)
      end

      def unquote(:"remove_#{singularized_context}")(struct, tag) when is_binary(tag) do
        Taglet.remove(struct, tag, unquote(context), [])
      end
      def unquote(:"remove_#{singularized_context}")(struct, tag, opts) do
        Taglet.remove(struct, tag, unquote(context), opts)
      end

      def unquote(:"#{singularized_context}_list")(struct) do
        Taglet.tag_list(struct, unquote(context), [])
      end
      def unquote(:"#{singularized_context}_list")(struct, opts) do
        Taglet.tag_list(struct, unquote(context), opts)
      end

      def unquote(:"#{context}")() do
        Taglet.tag_list(__MODULE__, unquote(context), [])
      end
      def unquote(:"#{context}")(opts) do
        Taglet.tag_list(__MODULE__, unquote(context), opts)
      end

      def unquote(:"#{context}_queryable")() do
        Taglet.tag_list_queryable(__MODULE__, unquote(context))
      end

      def unquote(:"tagged_with_#{singularized_context}")(tag) do
        Taglet.tagged_with(tag, __MODULE__, unquote(context), [])
      end
      def unquote(:"tagged_with_#{singularized_context}")(tag, opts) do
        Taglet.tagged_with(tag, __MODULE__, unquote(context), opts)
      end

      def unquote(:"tagged_with_#{context}")(tags) do
        Taglet.tagged_with(tags, __MODULE__, unquote(context), [])
      end
      def unquote(:"tagged_with_#{context}")(tags, opts) do
        Taglet.tagged_with(tags, __MODULE__, unquote(context), opts)
      end

      def unquote(:"tagged_with_query_#{singularized_context}")(queryable, tag) do
        Taglet.tagged_with_query(queryable, tag, unquote(context))
      end

      def unquote(:"tagged_with_query_#{context}")(queryable, tags) do
        Taglet.tagged_with_query(queryable, tags, unquote(context))
      end
    end
  end

  defmacro __before_compile__(_env) do

    quote do
      @contexts
      |> Enum.each(fn(context) ->
        singularized_context = Inflex.singularize(context)

        Module.eval_quoted(__MODULE__, quote do
          def unquote(:"add_#{context}")(tags) do
            Taglet.add(%__MODULE__{}, tags, unquote(context), [])
          end
          def unquote(:"add_#{context}")(tags, opts) do
            Taglet.add(%__MODULE__{}, tags, unquote(context), opts)
          end

          def unquote(:"add_#{singularized_context}")(tags) do
            Taglet.add(%__MODULE__{}, tags, unquote(context), [])
          end
          def unquote(:"add_#{singularized_context}")(tags, opts) do
            Taglet.add(%__MODULE__{}, tags, unquote(context), opts)
          end

          def unquote(:"remove_#{singularized_context}")(tag) do
            Taglet.remove(%__MODULE__{}, tag, unquote(context), [])
          end
          def unquote(:"remove_#{singularized_context}")(tag, opts) do
            Taglet.remove(%__MODULE__{}, tag, unquote(context), opts)
          end

          def unquote(:"rename_#{singularized_context}")(old_tag, new_tag) do
            Taglet.rename(%__MODULE__{}, old_tag, new_tag, unquote(context), [])
          end
          def unquote(:"rename_#{singularized_context}")(old_tag, new_tag, opts) do
            Taglet.rename(%__MODULE__{}, old_tag, new_tag, unquote(context), opts)
          end
        end)
      end)
    end

  end

end
