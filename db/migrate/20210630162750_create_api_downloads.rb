class CreateApiDownloads < ActiveRecord::Migration[6.1]
  def change
    create_table :api_downloads do |t|
      t.references :application, null: false, index: true, foreign_key: {to_table: :oauth_applications}
      t.string :url
      t.string :job_id
      t.timestamps
    end
  end
end
