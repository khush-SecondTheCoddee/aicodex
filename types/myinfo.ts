export type SocialLink = {
  label: string;
  url: string;
};

export type Project = {
  name: string;
  description: string;
  url?: string;
};

export type PersonalInfo = {
  name: string;
  role: string;
  location: string;
  bio: string;
  email: string;
  avatarUrl: string;
  skills: string[];
  socialLinks: SocialLink[];
  projects: Project[];
};
