namespace :db do

  task populate: :environment do
    system_admin = User.create!(name: "Nathanael Lin",
                                email: "nathanael.lin@tangtechnical.com",
                                password: "tangtech",
                                password_confirmation: "tangtech")
    system_admin.toggle!(:admin)
    system_admin.toggle!(:internal_user)
    system_admin.toggle!(:internal_user_part_approver)

    sales_manager = User.create!(name: "Sarah Tang",
                                 email: "sarah.tang@tangtechnical.com",
                                 password: "tangtech",
                                 password_confirmation: "tangtech")
    sales_manager.toggle!(:internal_user)
    sales_manager.toggle!(:internal_user_part_approver)
    sales_manager.toggle!(:internal_user_rfq_approver)

    Customer.create!(name: "PT Aker Solutions",
                     short_name: "Aker",
                     branch: "Batam",
                     domain: "akersolutions.com")

    # User.create!(name: "Normal User",
    #              email: "example@railstutorial.org",
    #              password: "foobar",
    #              password_confirmation: "foobar")

    # 1.times do |n|
    #  name  = Faker::Name.name
    #  email = "example-#{n+1}@railstutorial.org"
    #  password  = "password"
    #  User.create!(name: name,
    #               email: email,
    #               password: password,
    #               password_confirmation: password)
    # end
  end
end