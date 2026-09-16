const rawBaseUrl = import.meta.env.BASE_URL || "http://localhost:5119";

export const API_BASE = `${rawBaseUrl.replace(/\/+$/, "")}/api`;
