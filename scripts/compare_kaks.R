#!/usr/bin/env Rscript

library(tidyverse)
library(ggplot2)
library(fs)
library(RColorBrewer)
library(cowplot)
library(foreach)
library(nationalparkcolors)
#library(wesanderson)
#library(NatParksPalettes)
#pal <- wes_palette("Darjeeling1")
#pal2 <- wes_palette("Darjeeling2")
#pal2 <- park_palette("Badlands", 3)
pal2 <- brewer.pal(5, "Set1") 

data_dir <- "duplication/kaks"
tsv_files <- fs::dir_ls(data_dir, regexp = "\\.tab$")
Prefix= str_c(data_dir,"/")
if (! file.exists("plots")){
  dir.create("plots")
}
pdf("plots/plot_hap02_intraspecific_molevo.pdf")
kaksall <- tsv_files %>% map_dfr(read_tsv, .id="source",show_col_types = FALSE) %>%
  mutate_at("source",str_replace,Prefix,"") %>% 
  mutate_at("source",str_replace,".tab","") %>%
  mutate_at("source",str_replace,"Trebouxia_sp._","") %>%  
  mutate_at("source",str_replace,".yn00","")
  
kaks <- kaksall %>% filter(dS < 0.5) %>% filter(dN < 0.5) %>% filter(source != "hap02_hap01" & 
                                                                       source != "hap02_cold")

p1<- ggplot(kaks %>% filter(! grepl("Hap2_h1-vs-h2",source)), aes(x = log(dS)/log(10), fill = source)) +
  geom_histogram(position = "identity", bins = 100, alpha=0.5)  + theme_cowplot(12) + scale_fill_manual(values = pal2) +
  ggtitle("dS within-strain/haplotype pairwise Paralogs")
p1

p2<- ggplot(kaks %>% filter(! grepl("Hap2_h[12]$",source)), aes(x = log(dS)/log(10), fill = source)) +
  geom_histogram(position = "identity", bins = 100, alpha=0.5)  + theme_cowplot(12) + scale_fill_manual(values = pal2) +
  ggtitle("dS pairwise (Ortholog vs Paralog)")
#p2

p3 <- ggplot(kaks %>% filter(! grepl("Hap2_h[12]$",source)) %>% filter(dS > 0.01), 
             aes(x = log(dS)/log(10), fill = source)) +
  geom_histogram(position = "identity", bins = 100, alpha=0.5)  + theme_cowplot(12) + scale_fill_manual(values = pal2) +
  ggtitle("dS pairwise (Ortholog vs Paralog) (bigger than 0.01)")
#p3

prow = plot_grid(p2,p3,ncol = 1)
prow
p5 <- ggplot(kaks %>% filter(! grepl("Hap2_h[12]$",source)) %>% filter(OMEGA < 2), 
             aes(x = OMEGA, fill = source)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 100) + scale_fill_manual(values = pal2)  + theme_cowplot(12) +
  ggtitle("dN/dS pairwise")
p5
dev.off()
# === 
pdf("plots/plot_hap02_interspecific_molevo.pdf")
kakshaplocompare <- kaksall %>% filter(source == "hap02_hap01" | 
                                         source == "hap02_cold" | source == "Hap2") %>% filter(dS < 4)


p2<- ggplot(kakshaplocompare, aes(x = dS, fill = source)) +
  geom_histogram(position = "identity", bins = 100, alpha=0.5)  + theme_cowplot(12) + scale_fill_manual(values = pal2) +
  ggtitle("dS pairwise (Ortholog vs Paralog)")
p2


p5 <- ggplot(kakshaplocompare %>% filter(OMEGA < 2), aes(x = OMEGA, fill = source)) +
  geom_histogram(position = "identity", alpha = 0.5, bins = 100) + scale_fill_manual(values = pal2)  + theme_cowplot(12) +
  ggtitle("dN/dS pairwise")
p5
