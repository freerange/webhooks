class Harmonia
  def mark_as_done(email:, password:, task_url:)
    agent = Mechanize.new
    sign_in_page = agent.get("https://harmonia.io/sign-in")
    sign_in_page.form_with(action: '/session') do |sign_in_form|
      sign_in_form['email'] = email
      sign_in_form['password'] = password
    end.submit
    task_page = agent.get(task_url)
    task_page.form_with(action: %r{/done$}).submit
  end
end
