import { signIn } from "./actions";
import styles from "./login.module.css";

export default function Login() {
  return (
    <main className={styles.page}>
      <section className={styles.card}>
        <span className="mark">iF</span>
        <span className="eyebrow purple">AFTiFest Mission Control</span>
        <h1>Sign in to Mission Control</h1>
        <p>Accounts are provisioned by an authorized workspace administrator. Self-registration is disabled.</p>
        <form action={signIn} className={styles.form}>
          <label>Email<input name="email" type="email" autoComplete="email" required /></label>
          <label>Password<input name="password" type="password" autoComplete="current-password" required /></label>
          <button className="button primary" type="submit">Sign in</button>
        </form>
        <p className={styles.note}>Authentication establishes identity. Database policies still enforce organization and record access.</p>
      </section>
    </main>
  );
}
