class Harmonia
  def mark_as_done(email:, password:, task_url:)
    agent = Mechanize.new
    if File.exist?('cookies.yml')
      agent.cookie_jar.load('cookies.yml')
    end
    session_cookie = agent.cookie_jar.dup.find { |c| c.name = "_harmonia-next_session" }
    session_expired = session_cookie && session_cookie.expires < Time.now
    if session_cookie.nil? || session_expired
      sign_in_page = agent.get("https://harmonia.io/sign-in")
      sign_in_page.form_with(action: '/session') do |sign_in_form|
        sign_in_form['email'] = email
        sign_in_form['password'] = password
      end.submit
      agent.cookie_jar.save('cookies.yml', session: true)
    end
    task_page = agent.get(task_url)
    task_page.form_with(action: %r{/done$}).submit
  end
end
