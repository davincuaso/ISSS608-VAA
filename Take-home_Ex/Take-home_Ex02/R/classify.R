# EHSA timing rules; new and consecutive histories take precedence over oscillating.
class_eh <- function(z, p, tau, mp) {
    hot <- p < 0.05 & z > 0
    cold <- p < 0.05 & z < 0
    N <- length(z)
    for (side in c("hot", "cold")) {
        a <- if (side == "hot")
            hot else cold
        opp <- if (side == "hot")
            cold else hot
        name <- if (side == "hot")
            "hot spot" else "cold spot"
        if (!a[N] && sum(a) >= 0.9 * N)
            return(paste("Historical", name))
        if (a[N]) {
            if (sum(a) == 1)
                return(paste("New", name))
            if (sum(a) >= 0.9 * N) {
                trend <- if (side == "hot")
                  tau else -tau
                return(paste(if (mp < 0.05) if (trend > 0) "Intensifying" else "Diminishing" else "Persistent",
                  name))
            }
            if (all(a[min(which(a)):N]))
                return(paste("Consecutive", name))
            if (any(opp))
                return(paste("Oscillating", name))
            return(paste("Sporadic", name))
        }
    }
    "No pattern detected"
}
