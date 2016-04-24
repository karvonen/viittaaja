class Reference < ActiveRecord::Base
  belongs_to :user
  has_and_belongs_to_many :tags

  validates :title, :publisher, :year, presence: true, if: "reference_type=='book'"
  validate :author_xor_editor
  validate :drop_unnecessary_fields
  validates :author, :title, :journal, :year, :volume, presence: true, if: "reference_type=='article'"
  validates :author, :title, :booktitle, :year, presence: true, if: "reference_type=='inproceeding'"
  validates :year, :volume, :series, numericality: { allow_blank: true }

	scope :books, -> { where reference_type: 'book' }
  scope :articles, -> { where reference_type: 'article' }
  scope :inproceedings, -> { where reference_type: 'inproceeding' }



  def generate_citation_key(addition = '')
    key = "#{self.creator[0,2].downcase}#{self.year}#{addition}"

    nextChar = addition.empty? ? 'a' : (addition.ord + 1).chr
    key = self.generate_citation_key(nextChar) if Reference.where(citation_key:key).any?

    key
  end

  def creator
    return editor if author.nil? or author.empty?
    author
  end

  private
  def drop_unnecessary_fields
  	if self.reference_type=='book'
  		self.journal = ''
  		self.pages = ''
  		self.booktitle = ''
  		self.address = ''
  		self.organization = ''
  	end
  	if self.reference_type=='article'
  		self.editor = ''
  		self.series = ''
  		self.edition = ''
  	end
  	if self.reference_type=='inproceeding'
  		self.edition = ''
  		self.journal = ''
  	end
  end

  private
  def author_xor_editor
    if reference_type=='book'
      unless author.blank? ^ editor.blank?
        errors.add(:author, "or editor must be specified, but not both")
        errors.add(:editor, "or author must be specified, but not both")
      end
    end
  end
end
