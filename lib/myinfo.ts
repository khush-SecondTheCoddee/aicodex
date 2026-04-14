import infoData from "../myinfo.json";
import type { PersonalInfo } from "@/types/myinfo";

export function getMyInfo(): PersonalInfo {
  return infoData as PersonalInfo;
}
