import { getMyInfo } from "@/lib/myinfo";

export default function Home() {
  const info = getMyInfo();

  return (
    <main className="page">
      <section className="card hero">
        <img className="avatar" src={info.avatarUrl} alt={`${info.name} profile`} />
        <div>
          <h1>{info.name}</h1>
          <p className="subtitle">
            {info.role} • {info.location}
          </p>
          <p>{info.bio}</p>
          <a className="button" href={`mailto:${info.email}`}>
            Contact Me
          </a>
        </div>
      </section>

      <section className="card">
        <h2>Skills</h2>
        <ul className="pillList">
          {info.skills.map((skill) => (
            <li key={skill}>{skill}</li>
          ))}
        </ul>
      </section>

      <section className="card">
        <h2>Projects</h2>
        <ul className="stackedList">
          {info.projects.map((project) => (
            <li key={project.name}>
              <h3>{project.name}</h3>
              <p>{project.description}</p>
              {project.url ? (
                <a href={project.url} target="_blank" rel="noreferrer">
                  Visit project
                </a>
              ) : null}
            </li>
          ))}
        </ul>
      </section>

      <section className="card">
        <h2>Find Me Online</h2>
        <ul className="linkList">
          {info.socialLinks.map((link) => (
            <li key={link.label}>
              <a href={link.url} target="_blank" rel="noreferrer">
                {link.label}
              </a>
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}
