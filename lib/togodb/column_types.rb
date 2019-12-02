module Togodb
  class ColumnTypes

    class << self

      def supported_types
        [
            {
                label: 'DNA/Protein sequence',
                name: 'sequence',
                pattern: nil,
                link: '',
                identifiers_org: nil
            },
            {
                label: 'NCBI accession',
                name: 'GenBank',
                pattern: /\w+(\_)?\d+(\.\d+)?/,
                link: 'http://identifiers.org/insdc/{id}',
                identifiers_org: 'http://identifiers.org/insdc/{id}'
            },
            {
                label: 'EMBL accession',
                name: 'EMBL',
                pattern: /\w+(\_)?\d+(\.\d+)?/,
                link: 'http://identifiers.org/insdc/{id}',
                identifiers_org: 'http://identifiers.org/insdc/{id}'
            },
            {
                label: 'DDBJ accession',
                name: 'DDBJ',
                pattern: /\w+(\_)?\d+(\.\d+)?/,
                link: 'http://identifiers.org/insdc/{id}',
                identifiers_org: 'http://identifiers.org/insdc/{id}'
            },
            {
                label: 'UniProt ID',
                name: 'UniProt',
                pattern: /([A-N,R-Z][0-9][A-Z][A-Z, 0-9][A-Z, 0-9][0-9])|([O,P,Q][0-9][A-Z, 0-9][A-Z, 0-9][A-Z, 0-9][0-9])/,
                link: 'http://identifiers.org/uniprot/{id}',
                identifiers_org: 'http://identifiers.org/uniprot/{id}'
            },
            {
                label: 'PDB ID',
                name: 'PDB',
                pattern: /[0-9][A-Z0-9]{3}/,
                link: 'http://identifiers.org/pdb/{id}',
                identifiers_org: 'http://identifiers.org/pdb/{id}'
            },
            {
                label: 'PubMed ID',
                name: 'PubMed',
                pattern: /\d+/,
                link: 'http://identifiers.org/pubmed/{id}',
                identifiers_org: 'http://identifiers.org/pubmed/{id}'
            },
            {
                label: 'GO ID',
                name: 'GO',
                pattern: /GO:\d{7}/,
                link: 'http://identifiers.org/go/{id}',
                identifiers_org: 'http://identifiers.org/go/{id}'
            },
            {
                label: 'InterPro accession',
                name: 'InterPro',
                pattern: /IPR\d{6}/,
                link: 'http://identifiers.org/interpro/{id}',
                identifiers_org: 'http://identifiers.org/interpro/{id}'
            },
            {
                label: 'Pfam accession',
                name: 'Pfam',
                pattern: /PF\d{5}/,
                link: 'http://identifiers.org/pfam/{id}',
                identifiers_org: 'http://identifiers.org/pfam/{id}'
            },
            {
                label: 'Rfam accession',
                name: 'Rfam',
                pattern: /RF\d{5}/,
                link: 'http://identifiers.org/rfam/{id}',
                identifiers_org: 'http://identifiers.org/rfam/{id}'
            },
            {
                label: 'Taxonomy ID',
                name: 'Taxonomy',
                pattern: /\d+/,
                link: 'http://identifiers.org/taxonomy/{id}',
                identifiers_org: 'http://identifiers.org/taxonomy/{id}'
            },
            {
                label: 'DOI',
                name: 'DOI',
                pattern: /\.+/,
                link: 'http://doi.org/{id}',
                identifiers_org: nil
            }
        ]
      end

      def select_tag_options
        [
            ['Basic', [
                ['String     (<256 chars)', 'string'],
                ['Text      (>=256 chars)', 'text'],
                ['Integer   (<=11 digits)', 'integer'],
                ['BigInt                 ', 'bigint'],
                ['Float    (less precise)', 'float'],
                ['Decimal (most accurate)', 'decimal'],
                ['Date       (YYYY-MD-DD)', 'date'],
                ['DateTime (YYYY-MM-DD H:M:S)', 'datetime'],
                #["Timestamp with timezone (YYYY-MM-DD H:M:S)", "timestamp with time zone"],
                ['Boolean      (T/F, 1/0)', 'boolean'],
            #["Binary",                  "binary"],
            ]],
            ['Advanced', [
                ['Categorical data', 'list'],
            ]],
            ['Bio',
             Togodb::ColumnTypes.supported_types.map { |hash| [hash[:label], hash[:name]] }
            ]
        ]
      end

      def bio_types
        supported_types.map { |item| item[:name] }
      end

      def other_types
        %w[list] + bio_types
      end

      def type_for_migrate(type)
        other_types = supported_types.map { |item| item[:name] }
        case type
        when 'list'
          'string'
        when *other_types
          target = supported_types.select { |item| item[:name] == type }
          if target.is_a?(Array) && target[0][:pattern] == /\d+/
            'integer'
          else
            'string'
          end
        else
          type
        end
      end

      def link_template(other_type, column_name)
        item = supported_types.select { |type| type[:name] == other_type }
        if item.is_a?(Array)
          item[0][:link].gsub('{id}', "{#{column_name}}")
        else
          ''
        end
      end

    end

  end
end
