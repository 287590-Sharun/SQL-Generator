/**********************************************************************
artefact name :- f_sls_ord_sched
description   :- f_sls_ord_sched sql generated via multi-pass CTE pipeline
----------------------------------------------------------------------
change log
version :   date :        description :                       changed by
----------------------------------------------------------------------
0.0         2026-06-22    auto-generated multi-pass            ai_agent
**********************************************************************/

with
header_extract as (
    select 
    concat('gbl', g_order_company_cd) as co_key,
    case 
        when exists (
            select 1 
            from mska 
            where mska.vbeln = vbep.vbeln 
              and mska.posnr = vbep.posnr
        ) then (
            coalesce(mska.kalab, 0) + 
            coalesce(mska.kains, 0) + 
            coalesce(mska.kaspe, 0) + 
            coalesce(mska.kavla, 0) + 
            coalesce(mska.kavin, 0) + 
            coalesce(mska.kavsp, 0)
        )
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    null as g_availability_dt_yyyymmdd,
    case 
        when vbap.kunnr is not null then vbap.kunnr
        else (
            select kunnr 
            from vbap as vbap_alt 
            where vbap_alt.vbeln = vbep.vbeln 
              and vbap_alt.parvw = 'RE/BP'
              and vbap_alt.posnr is null
            limit 1
        )
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or vbap.abgru = '' then null
        when vbap.aedat = 0 then vbap.erdat
        else vbap.aedat
    end as g_cancel_dt_yyyymmdd,
    null as g_cancel_qty_primary_uom,
    case 
        when upper(t001.waers) = 'RMB' then 'CNY'
        else t001.waers
    end as g_company_currency_cd,
    vbap.kdmat as g_customer_item_nbr,
    'NULL' as g_customer_po_line_nbr,
    case 
        when vbkd.bstkd is not null then vbkd.bstkd
        else (
            select b.bstkd 
            from vbkd as b 
            where b.vbeln = vbep.vbeln 
              and b.posnr is null
            limit 1
        )
    end as g_customer_po_nbr,
    case 
        when vbkd.bsark is not null then vbkd.bsark
        else (
            select b.bsark 
            from vbkd as b 
            where b.vbeln = vbep.vbeln 
              and b.posnr is null
            limit 1
        )
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') then trim(vbep.request_dt)
        else vbep.edatu
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' 
          and (coalesce(mska.kalab, 0) + coalesce(mska.kains, 0) + coalesce(mska.kaspe, 0) + coalesce(mska.kavla, 0) + coalesce(mska.kavin, 0) + coalesce(mska.kavsp, 0)) > 0 
        then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = any (
            select uepos 
            from vbap as vbap_inner 
            where vbap_inner.vbeln = vbap.vbeln
        ) then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when exists (
            select 1 
            from knvv 
            where knvv.kunnr = vbak.kunnr 
              and knvv.vkorg = vbak.vkorg 
              and knvv.vtweg = vbak.vtweg 
              and knvv.spart = vbak.spart 
              and knvv.kdgrp in ('05', '06', '07')
        ) or exists (
            select 1 
            from kna1 
            where kna1.kunnr = vbak.kunnr 
              and kna1.ktokd in ('ZSUB', 'IC3P')
        ) then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when exists (
            select 1 
            from tvep 
            where tvep.ettyp = vbep.ettyp 
              and tvep.bedsd = 'X'
        ) or exists (
            select 1 
            from tvep 
            where tvep.ettyp = vbep.ettyp 
              and tvep.knttp in ('M', 'X')
        ) then 'yes'
        when vbep.order_qty_primary_uom = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp is not null and vbep.lifsp != '' then 'yes'
        when vbak.lifsk is not null and vbak.lifsk != '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold
from vbep
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join vbkd on vbep.vbeln = vbkd.vbeln and vbep.posnr = vbkd.posnr
left join mska on vbep.vbeln = mska.vbeln and vbep.posnr = mska.posnr
),
item_extract as (
    select 
  concat('gbl', g_order_company_cd) as co_key,
  case 
    when exists (
      select 1 
      from mska 
      where mska.vbeln = vbep.vbeln 
        and mska.posnr = vbep.posnr
    ) then 
      coalesce(mska.kalab, 0) + coalesce(mska.kains, 0) + coalesce(mska.kaspe, 0) + coalesce(mska.kavla, 0) + coalesce(mska.kavin, 0) + coalesce(mska.kavsp, 0)
    else 
      g_shipped_qty_primary_uom
  end as g_allocated_qty_primary_uom,
  null as g_availability_dt_yyyymmdd,
  case 
    when vbap.kunnr is not null then vbap.kunnr
    else (
      select kunnr 
      from vbap as vbap_alt 
      where vbap_alt.vbeln = vbep.vbeln 
        and vbap_alt.parvw = 'RE/BP'
    )
  end as g_bill_to_customer_nbr,
  case 
    when vbap.abgru is null then null
    when vbap.aedat = 0 then vbap.erdat
    else vbap.aedat
  end as g_cancel_dt_yyyymmdd,
  null as g_cancel_qty_primary_uom,
  case 
    when upper(t001.waers) = 'RMB' then 'CNY'
    else upper(t001.waers)
  end as g_company_currency_cd,
  vbap.kdmat as g_customer_item_nbr,
  null as g_customer_po_line_nbr,
  case 
    when vbkd.bstkd is not null then vbkd.bstkd
    else (
      select bstkd 
      from vbkd as vbkd_alt 
      where vbkd_alt.vbeln = vbep.vbeln
    )
  end as g_customer_po_nbr,
  case 
    when vbkd.bsark is not null then vbkd.bsark
    else (
      select bsark 
      from vbkd as vbkd_alt 
      where vbkd_alt.vbeln = vbep.vbeln
    )
  end as g_customer_po_type,
  case 
    when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
    when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') then trim(vbep.request_dt)
    else vbep.edatu
  end as g_customer_request_dt_yyyymmdd,
  vbep.etenr as g_delivery_schedule_line_nbr,
  case 
    when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
    else 'no'
  end as g_flag_consignment_order,
  case 
    when vbap.uepos is not null and vbap.uepos <> 0 then 'yes'
    else 'no'
  end as g_flag_has_parent,
  case 
    when mska.sobkz = 'E' 
      and (coalesce(mska.kalab, 0) + coalesce(mska.kains, 0) + coalesce(mska.kaspe, 0) + coalesce(mska.kavla, 0) + coalesce(mska.kavin, 0) + coalesce(mska.kavsp, 0)) > 0 
    then 'yes'
    else 'no'
  end as g_flag_inventory_fully_allocated,
  case 
    when vbap.posnr = vbap.uepos then 'yes'
    else 'no'
  end as g_flag_is_parent,
  case 
    when kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
    when knvv.kdgrp in ('05', '06', '07') then 'yes'
    else 'no'
  end as g_flag_is_transfer_order,
  case 
    when tvep.bedsd = 'X' then 'yes'
    when tvep.bedsd is null and tvep.knttp in ('M', 'X') then 'yes'
    when vbep.order_qty_primary_uom = 0 then 'no'
    else 'no'
  end as g_flag_material_transacted,
  case 
    when vbep.lifsp is not null then 'yes'
    when vbak.lifsk is not null then 'yes'
    when vbuk.cmgst in ('B', 'C') then 'yes'
    else 'no'
  end as g_flag_on_hold
from vbep
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join marm on vbap.matnr = marm.matnr and vbep.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join d_date on vbap.erdat = cast(d_date.dt_key as string)
left join d_curncy_mth_rt on trim(d_curncy_mth_rt.yr_mth_nbr) = trim(d_date.fscl_yr_prd_nbr) 
  and trim(to_curncy_cd) = trim(vbak.waerk) 
  and trim(from_curncy_cd) = if(trim(upper(t001.waers)) = 'RMB', 'CNY', trim(upper(t001.waers)))
),
schedule_extract as (
    select 
    concat('gbl', g_order_company_cd) as co_key,
    case 
        when exists (
            select 1 
            from mska 
            where mska.vbeln = vbep.vbeln 
              and mska.posnr = vbep.posnr
        ) then (
            coalesce(mska.kalab, 0) + 
            coalesce(mska.kains, 0) + 
            coalesce(mska.kaspe, 0) + 
            coalesce(mska.kavla, 0) + 
            coalesce(mska.kavin, 0) + 
            coalesce(mska.kavsp, 0)
        )
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    null as g_availability_dt_yyyymmdd,
    case 
        when vbap.kunnr is not null then vbap.kunnr
        else (
            select kunnr 
            from vbap as vbap_alt 
            where vbap_alt.vbeln = vbep.vbeln 
              and vbap_alt.parvw = 'RE/BP'
              and vbap_alt.posnr is null
            limit 1
        )
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or vbap.abgru = '' then null
        else case 
            when vbap.aedat = 0 then vbap.erdat
            else vbap.aedat
        end
    end as g_cancel_dt_yyyymmdd,
    null as g_cancel_qty_primary_uom,
    case 
        when upper(trim(t001.waers)) = 'RMB' then 'CNY'
        else upper(trim(t001.waers))
    end as g_company_currency_cd,
    vbap.kdmat as g_customer_item_nbr,
    'NULL' as g_customer_po_line_nbr,
    case 
        when vbkd.bstkd is not null then vbkd.bstkd
        else (
            select bstkd 
            from vbkd as vbkd_alt 
            where vbkd_alt.vbeln = vbep.vbeln 
              and vbkd_alt.posnr is null
            limit 1
        )
    end as g_customer_po_nbr,
    case 
        when vbkd.bsark is not null then vbkd.bsark
        else (
            select bsark 
            from vbkd as vbkd_alt 
            where vbkd_alt.vbeln = vbep.vbeln 
              and vbkd_alt.posnr is null
            limit 1
        )
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') then trim(vbep.request_dt)
        else vbep.edatu
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' 
          and (coalesce(mska.kalab, 0) + coalesce(mska.kains, 0) + coalesce(mska.kaspe, 0) + coalesce(mska.kavla, 0) + coalesce(mska.kavin, 0) + coalesce(mska.kavsp, 0)) > 0 then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = vbap.uepos then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        when knvv.kdgrp in ('05', '06', '07') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' then 'yes'
        when tvep.bedsd is null and tvep.knttp in ('M', 'X') then 'yes'
        when vbep.order_qty_primary_uom = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp != '' then 'yes'
        when vbak.lifsk != '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold
from vbep
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join marm on vbap.matnr = marm.matnr and vbep.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join vbkd on vbep.vbeln = vbkd.vbeln and vbep.posnr = vbkd.posnr
left join kna1 on vbak.kunnr = kna1.kunnr
left join knvv on vbak.kunnr = knvv.kunnr and vbak.vkorg = knvv.vkorg and vbak.vtweg = knvv.vtweg and vbak.spart = knvv.spart
left join tvep on vbep.ettyp = tvep.ettyp
),
uom_conversion as (
    select 
    vbap.matnr,
    vbap.werks,
    vbap.vbeln,
    vbap.posnr,
    vbap.meins as g_primary_uom_cd,
    vbap.vrkme as g_order_uom_cd,
    case 
        when vbep.vrkme = vbap.meins 
        then vbep.bmeng
        else (marm.umrez / marm.umren) * vbep.bmeng
    end as g_order_qty_primary_uom,
    case 
        when vbep_bmeng.calculated_bmeng is not null and vbep_bmeng.calculated_bmeng > 0
        then vbep.bmeng
        else vbep.wmeng
    end as g_order_qty_order_uom,
    case 
        when order_type = 'DEMO' and ship_lines.sttrg = '7' then 0
        when tvap.fkrel in ('A','H','J','K','M','O','P','Q','R','T','U','V','W')
        then round((coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0)), 4)
        when trim(tvap.fkrel) = ''
        then 0
        else round((coalesce(order_qty_primary_uom, 0) - 
            (case 
                when lst.shipped_qty <> 0 then lst.shipped_qty
                when lst.shipped_qty = 0 and inv.invoice_qty <> 0 then inv.invoice_qty
                else 0
            end)), 0)
    end - coalesce(cancel_qty_primary_uom, 0) as g_open_qty_primary_uom,
    case 
        when trim(mbew.vprsv) = 'V'
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.verpr * 100, mbew.verpr) / currency_factor, 2)
        when trim(mbew.vprsv) = 'S'
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.stprs * 100, mbew.stprs) / currency_factor, 2)
    end as g_unit_cost_company_currency_primary_uom,
    case 
        when trim(vbap.waerk) = trim(t001.waers)
        then if(trim(vbap.waerk) = 'JPY', puom.price_uom * 100 * coalesce(vbkd.kursk, vbkd_derived.kursk), puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk)) * (tcurf.tfact / tcurf.ffact)
        else (puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk)) * (tcurf.tfact / tcurf.ffact)
    end as g_unit_price_company_currency_primary_uom,
    case 
        when vbap.waerk = 'JPY' 
        then price_uom * 100 
        else price_uom
    end as g_unit_price_order_currency_primary_uom,
    case 
        when mska_entry_exists = 1
        then coalesce(kalab, 0) + coalesce(kains, 0) + coalesce(kaspe, 0) + coalesce(kavla, 0) + coalesce(kavin, 0) + coalesce(kavsp, 0)
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    null as g_cancel_qty_primary_uom
from 
    vbep
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join marm on vbap.matnr = marm.matnr and vbep.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join d_date on vbap.erdat = cast(d_dt.dt_key as string)
left join d_curncy_mth_rt on trim(d_curncy_mth_rt.yr_mth_nbr) = trim(d_dt.fscl_yr_prd_nbr) and trim(to_curncy_cd) = trim(vbak.waerk) and trim(from_curncy_cd) = if(trim(upper(t001.waers)) = 'RMB', 'CNY', trim(upper(t001.waers)))
),
vbep_bmeng as (
    select 
    vbep.vbeln,
    vbep.posnr,
    sum(vbep.bmeng) as calculated_bmeng
from 
    vbep
group by 
    vbep.vbeln, 
    vbep.posnr
),
vbfa_dedup as (
    select 
    vbfa.vbeln as g_order_nbr,
    vbfa.posnn as g_order_line_nbr,
    vbfa.vbtyp_n as g_document_type,
    vbfa.vbelv as g_preceding_document_nbr,
    vbfa.posnv as g_preceding_document_line_nbr,
    vbfa.vbtyp_v as g_preceding_document_type,
    vbfa.erzet as g_document_creation_time,
    vbfa.erdat as g_document_creation_date,
    row_number() over (
        partition by vbfa.vbeln, vbfa.posnn 
        order by vbfa.erdat desc, vbfa.erzet desc
    ) as row_num
from vbfa
),
order_schedule as (
    select 
    vbep.etenr as g_delivery_schedule_line_nbr,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    sum(vbep_bmeng.confirmed_qty) over (
        partition by vbep.vbeln, vbep.posnr 
        order by vbep.mbdat
    ) as running_total_qty
from 
    vbep_bmeng
left join 
    vbep 
    on vbep_bmeng.vbeln = vbep.vbeln 
    and vbep_bmeng.posnr = vbep.posnr
where 
    vbep_bmeng.confirmed_qty > 0
),
order_shipment as (
    select
    vbfa.vbelv,
    vbfa.vbeln,
    vbfa.posnv,
    vbfa.posnn,
    vbfa.vbtyp_n,
    sum(vbfa.rfmng) over (partition by vbfa.vbelv, vbfa.posnv order by vbfa.erdat rows between unbounded preceding and current row) as g_shipped_qty_primary_uom,
    first_value(vbfa.erdat) over (partition by vbfa.vbelv, vbfa.posnv order by vbfa.erdat desc) as g_last_actual_ship_dt_yyyymmdd
from
    vbfa_dedup vbfa
where
    vbfa.vbtyp_n = 'J' and vbfa.rfmng > 0
),
last_shipped_dt as (
    select 
    schedule_line_id,
    first_value(actual_ship_date) over (
        partition by schedule_line_id 
        order by actual_ship_date desc
    ) as g_last_actual_ship_dt_yyyymmdd
from 
    order_shipment
),
order_invoice as (
    select 
    vbfa.vbeln as order_id,
    vbfa.posnr as order_line_id,
    vbfa.erdat as g_invoice_dt_yyyymmdd,
    sum(vbfa.fkimg) as invoice_qty
from 
    vbfa
where 
    vbfa.vbtyp_n = 'J' -- Invoice document type
group by 
    vbfa.vbeln, 
    vbfa.posnr, 
    vbfa.erdat
),
tcurf_dedup as (
    select 
    tcurf.ffact as from_currency_factor,
    tcurf.tfact as to_currency_factor,
    tcurf.ffact / tcurf.tfact as currency_factor,
    tcurf.from_curncy_cd,
    tcurf.to_curncy_cd,
    tcurf.yr_mth_nbr,
    row_number() over (
        partition by tcurf.from_curncy_cd, tcurf.to_curncy_cd, tcurf.yr_mth_nbr 
        order by tcurf.last_updated_dt desc
    ) as row_num
from 
    tcurf
),
final_joined as (
    select
    concat_ws('|', 'gbl', g_order_company_cd) as co_key,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp)
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    cast(null as string) as g_availability_dt_yyyymmdd,
    case 
        when bp.bill_to_customer_nbr is not null then bp.bill_to_customer_nbr
        else bp_alt.bill_to_customer_nbr
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or trim(vbap.abgru) = '' then null
        else coalesce(vbap.aedat, vbap.erdat)
    end as g_cancel_dt_yyyymmdd,
    cast(null as string) as g_cancel_qty_primary_uom,
    case 
        when trim(t001.waers) = 'RMB' then 'CNY'
        else trim(t001.waers)
    end as g_company_currency_cd,
    vbap.matnr as g_customer_item_nbr,
    cast(null as string) as g_customer_po_line_nbr,
    case 
        when po.customer_po_nbr is not null then po.customer_po_nbr
        else po_alt.customer_po_nbr
    end as g_customer_po_nbr,
    case 
        when po.customer_po_type is not null then po.customer_po_type
        else po_alt.customer_po_type
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = any(select uepos from vbap where vbap.vbeln = vbap.vbeln) then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when knvv.kdgrp in ('05', '06', '07') or kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' or tvep.knttp in ('M', 'X') then 'yes'
        when coalesce(order_qty_primary_uom, 0) = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp is not null then 'yes'
        when vbak.lifsk is not null then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold,
    case 
        when vbak.autlf = 'X' then 'no'
        when cancel_qty_primary_uom = order_qty_primary_uom then 'no'
        when open_qty_primary_uom <= 0 then 'no'
        else 'yes'
    end as g_flag_open_to_ship,
    case 
        when vbak.vbtyp in ('H', 'T') then 'yes'
        else 'no'
    end as g_flag_return,
    case 
        when order_qty_primary_uom = 0 then 'no'
        when trim(vbak.vbtyp) in ('A', 'B', 'D') then 'no'
        when trim(tvap.prsfd) = 'X' then 'yes'
        else 'no'
    end as g_flag_revenue_recognition,
    inco_terms.inco_terms as g_inco_terms,
    vbfa.erdat as g_invoice_dt_yyyymmdd,
    vbap.matnr as g_item_nbr,
    cast(null as string) as g_last_actual_ship_dt_yyyymmdd,
    case 
        when upper(trim(vbup.gbsta)) = 'A' then 'NOT YET PROCESSED'
        when upper(trim(vbup.gbsta)) = 'B' then 'PARTIALLY PROCESSED'
        when upper(trim(vbup.gbsta)) = 'C' then 'COMPLETELY PROCESSED'
        else 'NOT RELEVANT'
    end as g_line_status_cd,
    case 
        when order_type = 'DEMO' and ship_lines.sttrg = '7' then 0
        when tvap.fkrel in ('A', 'H', 'J', 'K', 'M', 'O', 'P', 'Q', 'R', 'T', 'U', 'V', 'W') 
        then round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 4)
        when trim(tvap.fkrel) = '' then 0
        else round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 0)
    end - coalesce(cancel_qty_primary_uom, 0) as g_open_qty_primary_uom,
    vbap.pstyv as g_order_category,
    t001k.bukrs as g_order_company_cd,
    case 
        when trim(vbak.waerk) = 'RMB' then 'CNY'
        else trim(vbak.waerk)
    end as g_order_currency_cd,
    vbak.aedat as g_order_dt_yyyymmdd,
    vbep.posnr as g_order_line_nbr,
    vbep.vbeln as g_order_nbr,
    case 
        when vbep_bmeng.calculated_bmeng is not null and vbep_bmeng.calculated_bmeng > 0 then vbep.bmeng
        else vbep.wmeng
    end as g_order_qty_order_uom,
    case 
        when vbep_bmeng.calculated_bmeng is not null and vbep_bmeng.calculated_bmeng > 0 then vbep.bmeng
        else vbep.wmeng
    end as g_order_qty_primary_uom,
    case 
        when vbak.auart = 'TA' then 'OR'
        else vbak.auart
    end as g_order_type,
    trim(vbap.vrkme) as g_order_uom_cd,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu
    end as g_original_customer_request_dt_yyyymmdd,
    case 
        when trim(vbap.werks) = '0070' then vbak.zz_ship_by
        else coalesce(zosdates.lddat, vbep.edatu)
    end as g_original_promised_ship_dt_yyyymmdd,
    vbap.uepos as g_parent_order_line_nbr,
    vbak.zterm as g_payment_terms,
    vbap.werks as g_plant_cd,
    trim(vbap.meins) as g_primary_uom_cd,
    case 
        when trim(vbap.werks) = '0070' then vbak.zz_ship_by
        else trim(vbep.edatu)
    end as g_promised_ship_dt_yyyymmdd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    case 
        when ship_to.ship_to_customer_nbr is not null then ship_to.ship_to_customer_nbr
        else ship_to_alt.ship_to_customer_nbr
    end as g_ship_to_customer_nbr,
    datediff(vbep.mbdat, vbep.edatu) as g_ship_to_delivery_days,
    tvsbt.vsbed as g_shipment_mode,
    vbfa.rfmng as g_shipped_qty_primary_uom,
    'GBL' as g_source_system_cd,
    case 
        when trim(mbew.vprsv) = 'V' 
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.verpr * 100, mbew.verpr) / currency_factor, 2)
        when trim(mbew.vprsv) = 'S' 
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.stprs * 100, mbew.stprs) / currency_factor, 2)
    end as g_unit_cost_company_currency_primary_uom,
    case 
        when trim(vbap.waerk) = trim(t001.waers) 
        then if(trim(vbap.waerk) = 'JPY', puom.price_uom * 100 * coalesce(vbkd.kursk, vbkd_derived.kursk), puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk)) * (tcurf.tfact / tcurf.ffact)
        else (puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk)) * (tcurf.tfact / tcurf.ffact)
    end as g_unit_price_company_currency_primary_uom,
    case 
        when vbep.vrkme = vbap.meins 
        then vbep.bmeng
        else (marm.umrez / marm.umren) * vbep.bmeng
    end as g_unit_price_order_currency_primary_uom,
    concat_ws('|', 'gbl', vbap.werks) as plant_key,
    concat_ws('|', 'gbl', vbap.matnr) as prod_key,
    concat_ws('|', 'gbl', vbap.matnr, vbap.werks) as prod_plant_key,
    concat_ws('|', 'gbl', t001k.bukrs, vbak.auart, vbep.vbeln) as sls_ord_key,
    concat_ws('|', 'gbl', t001k.bukrs, vbak.auart, vbep.vbeln, vbep.posnr, vbep.etenr) as sls_ord_sched_key,
    cast(null as string) as flag_is_blanket
from
    header_extract he
left join item_extract ie on he.vbeln = ie.vbeln
left join schedule_extract se on ie.vbeln = se.vbeln and ie.posnr = se.posnr
left join uom_conversion uc on ie.matnr = uc.matnr and se.vrkme = uc.meinh
left join order_schedule os on se.vbeln = os.vbeln and se.posnr = os.posnr
left join order_shipment ship on os.vbeln = ship.vbeln and os.posnr = ship.posnr
left join last_shipped_dt lst on ship.vbeln = lst.vbeln and ship.posnr = lst.posnr
left join order_invoice oi on lst.vbeln = oi.vbeln and lst.posnr = oi.posnr
left join tcurf_dedup tcurf on oi.waerk = tcurf.ffact and tcurf.tfact = t001.waers
),
final_joined_with_flags as (
    select
    concat_ws('|', 'gbl', g_order_company_cd) as co_key,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp)
        else g_shipped_qty_primary_uom 
    end as g_allocated_qty_primary_uom,
    cast(null as string) as g_availability_dt_yyyymmdd,
    case 
        when bp.bill_to_customer_nbr is not null then bp.bill_to_customer_nbr
        else bp_alt.bill_to_customer_nbr 
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null or trim(vbap.abgru) = '' then null
        when vbap.aedat = '0' then vbap.erdat
        else vbap.aedat 
    end as g_cancel_dt_yyyymmdd,
    cast(null as string) as g_cancel_qty_primary_uom,
    case 
        when trim(t001.waers) = 'RMB' then 'CNY'
        else trim(t001.waers) 
    end as g_company_currency_cd,
    vbap.matnr as g_customer_item_nbr,
    cast(null as string) as g_customer_po_line_nbr,
    case 
        when po.customer_po_nbr is not null then po.customer_po_nbr
        else po_alt.customer_po_nbr 
    end as g_customer_po_nbr,
    case 
        when po.customer_po_type is not null then po.customer_po_type
        else po_alt.customer_po_type 
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu 
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no' 
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != '0' then 'yes'
        else 'no' 
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' and (mska.kalab + mska.kains + mska.kaspe + mska.kavla + mska.kavin + mska.kavsp) > 0 
        then 'yes'
        else 'no' 
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = any(select uepos from vbap where vbap.vbeln = vbap.vbeln) then 'yes'
        else 'no' 
    end as g_flag_is_parent,
    case 
        when knvv.kdgrp in ('05', '06', '07') or kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        else 'no' 
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' or tvep.knttp in ('M', 'X') then 'yes'
        when coalesce(order_qty_primary_uom, 0) = 0 then 'no'
        else 'no' 
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp is not null and trim(vbep.lifsp) != '' then 'yes'
        when vbak.lifsk is not null and trim(vbak.lifsk) != '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no' 
    end as g_flag_on_hold,
    case 
        when vbak.autlf = 'X' then 'no'
        when cancel_qty_primary_uom = order_qty_primary_uom then 'no'
        when open_qty_primary_uom <= 0 then 'no'
        else 'yes' 
    end as g_flag_open_to_ship,
    case 
        when vbak.vbtyp in ('H', 'T') then 'yes'
        else 'no' 
    end as g_flag_return,
    case 
        when coalesce(order_qty_primary_uom, 0) = 0 then 'no'
        when trim(vbak.vbtyp) in ('A', 'B', 'D') then 'no'
        when trim(tvap.prsfd) = 'X' then 'yes'
        else 'no' 
    end as g_flag_revenue_recognition,
    inco_terms.inco_terms as g_inco_terms,
    vbfa.erdat as g_invoice_dt_yyyymmdd,
    vbap.matnr as g_item_nbr,
    cast(null as string) as g_last_actual_ship_dt_yyyymmdd,
    case 
        when upper(trim(vbup.gbsta)) = 'A' then 'NOT YET PROCESSED'
        when upper(trim(vbup.gbsta)) = 'B' then 'PARTIALLY PROCESSED'
        when upper(trim(vbup.gbsta)) = 'C' then 'COMPLETELY PROCESSED'
        else 'NOT RELEVANT' 
    end as g_line_status_cd,
    case 
        when order_type = 'DEMO' and ship_lines.sttrg = '7' then 0
        when tvap.fkrel in ('A', 'H', 'J', 'K', 'M', 'O', 'P', 'Q', 'R', 'T', 'U', 'V', 'W') 
        then round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 4)
        when trim(tvap.fkrel) = '' then 0
        else round(coalesce(order_qty_primary_uom, 0) - coalesce(lst.shipped_qty, 0), 0) 
    end - coalesce(cancel_qty_primary_uom, 0) as g_open_qty_primary_uom,
    vbap.pstyv as g_order_category,
    t001k.bukrs as g_order_company_cd,
    case 
        when trim(vbak.waerk) = 'RMB' then 'CNY'
        else trim(vbak.waerk) 
    end as g_order_currency_cd,
    vbak.audat as g_order_dt_yyyymmdd,
    vbap.posnr as g_order_line_nbr,
    vbap.vbeln as g_order_nbr,
    case 
        when vbep_bmeng.calculated_bmeng is not null and vbep_bmeng.calculated_bmeng > 0 
        then vbep.bmeng
        else vbep.wmeng 
    end as g_order_qty_order_uom,
    case 
        when vbep_bmeng.calculated_bmeng is not null and vbep_bmeng.calculated_bmeng > 0 
        then vbep.bmeng
        else vbep.wmeng 
    end as g_order_qty_primary_uom,
    vbak.auart as g_order_type,
    vbap.vrkme as g_order_uom_cd,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu 
    end as g_original_customer_request_dt_yyyymmdd,
    case 
        when zosdates.lddat is not null then zosdates.lddat
        else coalesce(vbep.edatu, null) 
    end as g_original_promised_ship_dt_yyyymmdd,
    vbap.uepos as g_parent_order_line_nbr,
    vbak.zterm as g_payment_terms,
    vbap.werks as g_plant_cd,
    vbap.meins as g_primary_uom_cd,
    case 
        when trim(vbap.werks) = '0070' then vbak.zz_ship_by
        else trim(vbep.edatu) 
    end as g_promised_ship_dt_yyyymmdd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    case 
        when ship_to.ship_to_customer_nbr is not null then ship_to.ship_to_customer_nbr
        else ship_to_alt.ship_to_customer_nbr 
    end as g_ship_to_customer_nbr,
    datediff(vbep.mbdat, vbep.edatu) as g_ship_to_delivery_days,
    tvsbt.vsbed as g_shipment_mode,
    vbfa.rfmng as g_shipped_qty_primary_uom,
    'GBL' as g_source_system_cd,
    case 
        when trim(mbew.vprsv) = 'V' 
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.verpr * 100, mbew.verpr) / currency_factor, 2)
        when trim(mbew.vprsv) = 'S' 
        then round(if(t001.waers in ('KRW', 'JPY'), mbew.stprs * 100, mbew.stprs) / currency_factor, 2)
    end as g_unit_cost_company_currency_primary_uom,
    case 
        when trim(vbap.waerk) = trim(t001.waers) 
        then if(trim(vbap.waerk) = 'JPY', puom.price_uom * 100 * coalesce(vbkd.kursk, vbkd_derived.kursk), puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk)) * (tcurf.tfact / tcurf.ffact)
        else puom.price_uom * coalesce(vbkd.kursk, vbkd_derived.kursk) * (tcurf.tfact / tcurf.ffact) 
    end as g_unit_price_company_currency_primary_uom,
    case 
        when vbep.vrkme = vbap.meins 
        then vbep.bmeng
        else (marm.umrez / marm.umren) * vbep.bmeng 
    end as g_unit_price_order_currency_primary_uom,
    concat_ws('|', 'gbl', g_plant_cd) as plant_key,
    concat_ws('|', 'gbl', g_item_nbr) as prod_key,
    concat_ws('|', 'gbl', g_item_nbr, g_plant_cd) as prod_plant_key,
    concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr) as sls_ord_key,
    concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr, g_order_line_nbr, g_delivery_schedule_line_nbr) as sls_ord_sched_key,
    cast(null as string) as flag_is_blanket
from final_joined
),
sto_join as (
    select
    vbep.vbeln as g_order_nbr,
    vbep.posnr as g_order_line_nbr,
    vbep.etenr as g_delivery_schedule_line_nbr,
    vbep.bmeng as g_order_qty_order_uom,
    case
        when vbep.vrkme = vbap.meins then vbep.bmeng
        else (marm.umrez / marm.umren) * vbep.bmeng
    end as g_order_qty_primary_uom,
    vbap.vrkme as g_order_uom_cd,
    vbap.meins as g_primary_uom_cd,
    vbep.mbdat as g_scheduled_ship_dt_yyyymmdd,
    vbep.edatu as g_promised_ship_dt_yyyymmdd,
    vbap.werks as g_plant_cd,
    vbap.matnr as g_item_nbr,
    case
        when vbap.abgru is null or trim(vbap.abgru) = '' then null
        else case
            when vbap.aedat = '0' then vbap.erdat
            else vbap.aedat
        end
    end as g_cancel_dt_yyyymmdd,
    cast(null as string) as g_cancel_qty_primary_uom, -- TODO: review mapping
    case
        when trim(vbak.waerk) = 'RMB' then 'CNY'
        else trim(vbak.waerk)
    end as g_order_currency_cd,
    case
        when trim(t001.waers) = 'RMB' then 'CNY'
        else trim(t001.waers)
    end as g_company_currency_cd,
    cast(null as string) as g_availability_dt_yyyymmdd, -- TODO: review mapping
    cast(null as string) as g_customer_po_line_nbr, -- TODO: review mapping
    vbep.edatu as g_original_customer_request_dt_yyyymmdd,
    vbep.edatu as g_original_promised_ship_dt_yyyymmdd,
    case
        when vbak.autlf = 'X' then 'no'
        when vbap.abgru is not null and trim(vbap.abgru) <> '' then 'no'
        when vbep.bmeng <= 0 then 'no'
        else 'yes'
    end as g_flag_open_to_ship,
    case
        when vbak.vbtyp in ('H', 'T') then 'yes'
        else 'no'
    end as g_flag_return,
    case
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case
        when vbap.uepos is not null and vbap.uepos <> '0' then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case
        when vbap.posnr = vbap.uepos then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case
        when vbak.kunnr in (select kna1.kunnr from kna1 where kna1.ktokd in ('ZSUB', 'IC3P')) then 'yes'
        when vbak.kunnr in (select knvv.kunnr from knvv where knvv.kdgrp in ('05', '06', '07')) then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    cast(null as string) as g_flag_material_transacted, -- TODO: review mapping
    case
        when vbep.lifsp is not null and trim(vbep.lifsp) <> '' then 'yes'
        when vbak.lifsk is not null and trim(vbak.lifsk) <> '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold,
    cast(null as string) as g_flag_revenue_recognition, -- TODO: review mapping
    cast(null as string) as g_customer_item_nbr, -- TODO: review mapping
    cast(null as string) as g_customer_po_nbr, -- TODO: review mapping
    cast(null as string) as g_customer_po_type, -- TODO: review mapping
    cast(null as string) as g_inco_terms, -- TODO: review mapping
    cast(null as string) as g_invoice_dt_yyyymmdd, -- TODO: review mapping
    cast(null as string) as g_last_actual_ship_dt_yyyymmdd, -- TODO: review mapping
    case
        when upper(trim(vbup.gbsta)) = 'A' then 'NOT YET PROCESSED'
        when upper(trim(vbup.gbsta)) = 'B' then 'PARTIALLY PROCESSED'
        when upper(trim(vbup.gbsta)) = 'C' then 'COMPLETELY PROCESSED'
        else 'NOT RELEVANT'
    end as g_line_status_cd,
    cast(null as string) as g_open_qty_primary_uom, -- TODO: review mapping
    cast(null as string) as g_order_category, -- TODO: review mapping
    cast(null as string) as g_payment_terms, -- TODO: review mapping
    cast(null as string) as g_ship_to_customer_nbr, -- TODO: review mapping
    cast(null as string) as g_ship_to_delivery_days, -- TODO: review mapping
    cast(null as string) as g_shipment_mode, -- TODO: review mapping
    cast(null as string) as g_shipped_qty_primary_uom, -- TODO: review mapping
    'GBL' as g_source_system_cd,
    cast(null as string) as g_unit_cost_company_currency_primary_uom, -- TODO: review mapping
    cast(null as string) as g_unit_price_company_currency_primary_uom, -- TODO: review mapping
    cast(null as string) as g_unit_price_order_currency_primary_uom, -- TODO: review mapping
    concat_ws('|', 'gbl', vbap.werks) as plant_key,
    concat_ws('|', 'gbl', vbap.matnr) as prod_key,
    concat_ws('|', 'gbl', vbap.matnr, vbap.werks) as prod_plant_key,
    concat_ws('|', 'gbl', t001.bukrs, vbak.auart, vbep.vbeln) as sls_ord_key,
    concat_ws('|', 'gbl', t001.bukrs, vbak.auart, vbep.vbeln, vbep.posnr, vbep.etenr) as sls_ord_sched_key,
    cast(null as string) as flag_is_blanket -- TODO: review mapping
from vbep
left join vbap on vbep.vbeln = vbap.vbeln and vbep.posnr = vbap.posnr
left join marm on vbap.matnr = marm.matnr and vbep.vrkme = marm.meinh
left join mbew on vbap.matnr = mbew.matnr and vbap.werks = mbew.bwkey
left join vbak on vbep.vbeln = vbak.vbeln
left join t001 on t001.bukrs = vbak.bukrs_vf
left join vbup on vbep.vbeln = vbup.vbeln and vbep.posnr = vbup.posnr
),
main_select_with_union_all_so_sto as (
    select 
    concat('gbl', g_order_company_cd) as co_key,
    case 
        when exists (
            select 1 
            from mska 
            where mska.vbeln = final_joined_with_flags.g_order_nbr 
              and mska.posnr = final_joined_with_flags.g_order_line_nbr
        ) 
        then coalesce(
            sum(mska.kalab), 
            sum(mska.kains), 
            sum(mska.kaspe), 
            sum(mska.kavla), 
            sum(mska.kavin), 
            sum(mska.kavsp)
        )
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    null as g_availability_dt_yyyymmdd,
    case 
        when vbap.kunnr is not null then vbap.kunnr
        else (
            select kunnr 
            from vbap 
            where vbeln = final_joined_with_flags.g_order_nbr 
              and posnr is null 
              and parvw = 'RE/BP'
        )
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null then null
        when vbap.aedat = 0 then vbap.erdat
        else vbap.aedat
    end as g_cancel_dt_yyyymmdd,
    null as g_cancel_qty_primary_uom,
    case 
        when t001.waers = 'RMB' then 'CNY'
        else t001.waers
    end as g_company_currency_cd,
    vbap.kdmat as g_customer_item_nbr,
    'NULL' as g_customer_po_line_nbr,
    case 
        when vbkd.bstkd is not null then vbkd.bstkd
        else (
            select bstkd 
            from vbkd 
            where vbeln = final_joined_with_flags.g_order_nbr 
              and posnr is null
        )
    end as g_customer_po_nbr,
    case 
        when vbkd.bsark is not null then vbkd.bsark
        else (
            select bsark 
            from vbkd 
            where vbeln = final_joined_with_flags.g_order_nbr 
              and posnr is null
        )
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' 
          and (mska.kalab > 0 or mska.kains > 0 or mska.kaspe > 0 or mska.kavla > 0 or mska.kavin > 0 or mska.kavsp > 0) 
        then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = vbap.uepos then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        when knvv.kdgrp in ('05', '06', '07') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' then 'yes'
        when tvep.bedsd is null and tvep.knttp in ('M', 'X') then 'yes'
        when order_qty_primary_uom = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp != '' then 'yes'
        when vbak.lifsk != '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold
from final_joined_with_flags
union all
select 
    concat('gbl', g_order_company_cd) as co_key,
    case 
        when exists (
            select 1 
            from mska 
            where mska.vbeln = sto_join.g_order_nbr 
              and mska.posnr = sto_join.g_order_line_nbr
        ) 
        then coalesce(
            sum(mska.kalab), 
            sum(mska.kains), 
            sum(mska.kaspe), 
            sum(mska.kavla), 
            sum(mska.kavin), 
            sum(mska.kavsp)
        )
        else g_shipped_qty_primary_uom
    end as g_allocated_qty_primary_uom,
    null as g_availability_dt_yyyymmdd,
    case 
        when vbap.kunnr is not null then vbap.kunnr
        else (
            select kunnr 
            from vbap 
            where vbeln = sto_join.g_order_nbr 
              and posnr is null 
              and parvw = 'RE/BP'
        )
    end as g_bill_to_customer_nbr,
    case 
        when vbap.abgru is null then null
        when vbap.aedat = 0 then vbap.erdat
        else vbap.aedat
    end as g_cancel_dt_yyyymmdd,
    null as g_cancel_qty_primary_uom,
    case 
        when t001.waers = 'RMB' then 'CNY'
        else t001.waers
    end as g_company_currency_cd,
    vbap.kdmat as g_customer_item_nbr,
    'NULL' as g_customer_po_line_nbr,
    case 
        when vbkd.bstkd is not null then vbkd.bstkd
        else (
            select bstkd 
            from vbkd 
            where vbeln = sto_join.g_order_nbr 
              and posnr is null
        )
    end as g_customer_po_nbr,
    case 
        when vbkd.bsark is not null then vbkd.bsark
        else (
            select bsark 
            from vbkd 
            where vbeln = sto_join.g_order_nbr 
              and posnr is null
        )
    end as g_customer_po_type,
    case 
        when coalesce(request_date.land1, request_date_posnr0.land1) not in ('US', 'CA') 
        then coalesce(request_date.vdatu, request_date_posnr0.vbdatu)
        when coalesce(request_date.land1, request_date_posnr0.land1) in ('US', 'CA') 
        then trim(vbep.request_dt)
        else vbep.edatu
    end as g_customer_request_dt_yyyymmdd,
    vbep.etenr as g_delivery_schedule_line_nbr,
    case 
        when vbap.pstyv in ('KBN', 'KEN', 'KAN', 'KRN') then 'yes'
        else 'no'
    end as g_flag_consignment_order,
    case 
        when vbap.uepos is not null and vbap.uepos != 0 then 'yes'
        else 'no'
    end as g_flag_has_parent,
    case 
        when mska.sobkz = 'E' 
          and (mska.kalab > 0 or mska.kains > 0 or mska.kaspe > 0 or mska.kavla > 0 or mska.kavin > 0 or mska.kavsp > 0) 
        then 'yes'
        else 'no'
    end as g_flag_inventory_fully_allocated,
    case 
        when vbap.posnr = vbap.uepos then 'yes'
        else 'no'
    end as g_flag_is_parent,
    case 
        when kna1.ktokd in ('ZSUB', 'IC3P') then 'yes'
        when knvv.kdgrp in ('05', '06', '07') then 'yes'
        else 'no'
    end as g_flag_is_transfer_order,
    case 
        when tvep.bedsd = 'X' then 'yes'
        when tvep.bedsd is null and tvep.knttp in ('M', 'X') then 'yes'
        when order_qty_primary_uom = 0 then 'no'
        else 'no'
    end as g_flag_material_transacted,
    case 
        when vbep.lifsp != '' then 'yes'
        when vbak.lifsk != '' then 'yes'
        when vbuk.cmgst in ('B', 'C') then 'yes'
        else 'no'
    end as g_flag_on_hold
from sto_join
)
with final_select as (
    select
        concat_ws('|', 'gbl', g_order_company_cd) as co_key,
        g_allocated_qty_primary_uom,
        g_availability_dt_yyyymmdd,
        g_bill_to_customer_nbr,
        g_cancel_dt_yyyymmdd,
        g_cancel_qty_primary_uom,
        case when g_order_currency_cd = 'RMB' then 'CNY' else g_order_currency_cd end as g_company_currency_cd,
        g_customer_item_nbr,
        g_customer_po_line_nbr,
        g_customer_po_nbr,
        g_customer_po_type,
        g_customer_request_dt_yyyymmdd,
        g_delivery_schedule_line_nbr,
        g_flag_consignment_order,
        g_flag_has_parent,
        g_flag_inventory_fully_allocated,
        g_flag_is_parent,
        g_flag_is_transfer_order,
        g_flag_material_transacted,
        g_flag_on_hold,
        g_flag_open_to_ship,
        g_flag_return,
        g_flag_revenue_recognition,
        g_inco_terms,
        g_invoice_dt_yyyymmdd,
        g_item_nbr,
        g_last_actual_ship_dt_yyyymmdd,
        g_line_status_cd,
        g_open_qty_primary_uom,
        g_order_category,
        g_order_company_cd,
        g_order_currency_cd,
        g_order_dt_yyyymmdd,
        g_order_line_nbr,
        g_order_nbr,
        g_order_qty_order_uom,
        g_order_qty_primary_uom,
        g_order_type,
        g_order_uom_cd,
        g_original_customer_request_dt_yyyymmdd,
        g_original_promised_ship_dt_yyyymmdd,
        g_parent_order_line_nbr,
        g_payment_terms,
        g_plant_cd,
        g_primary_uom_cd,
        g_promised_ship_dt_yyyymmdd,
        g_scheduled_ship_dt_yyyymmdd,
        g_ship_to_customer_nbr,
        g_ship_to_delivery_days,
        g_shipment_mode,
        g_shipped_qty_primary_uom,
        'gbl' as g_source_system_cd,
        g_unit_cost_company_currency_primary_uom,
        g_unit_price_company_currency_primary_uom,
        g_unit_price_order_currency_primary_uom,
        concat_ws('|', 'gbl', g_plant_cd) as plant_key,
        concat_ws('|', 'gbl', g_item_nbr) as prod_key,
        concat_ws('|', 'gbl', g_item_nbr, g_plant_cd) as prod_plant_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr) as sls_ord_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr, g_order_line_nbr, g_delivery_schedule_line_nbr) as sls_ord_sched_key,
        flag_is_blanket
    from final_joined_with_flags
    union all
    select
        concat_ws('|', 'gbl', g_order_company_cd) as co_key,
        g_allocated_qty_primary_uom,
        g_availability_dt_yyyymmdd,
        g_bill_to_customer_nbr,
        g_cancel_dt_yyyymmdd,
        g_cancel_qty_primary_uom,
        case when g_order_currency_cd = 'RMB' then 'CNY' else g_order_currency_cd end as g_company_currency_cd,
        g_customer_item_nbr,
        g_customer_po_line_nbr,
        g_customer_po_nbr,
        g_customer_po_type,
        g_customer_request_dt_yyyymmdd,
        g_delivery_schedule_line_nbr,
        g_flag_consignment_order,
        g_flag_has_parent,
        g_flag_inventory_fully_allocated,
        g_flag_is_parent,
        g_flag_is_transfer_order,
        g_flag_material_transacted,
        g_flag_on_hold,
        g_flag_open_to_ship,
        g_flag_return,
        g_flag_revenue_recognition,
        g_inco_terms,
        g_invoice_dt_yyyymmdd,
        g_item_nbr,
        g_last_actual_ship_dt_yyyymmdd,
        g_line_status_cd,
        g_open_qty_primary_uom,
        g_order_category,
        g_order_company_cd,
        g_order_currency_cd,
        g_order_dt_yyyymmdd,
        g_order_line_nbr,
        g_order_nbr,
        g_order_qty_order_uom,
        g_order_qty_primary_uom,
        g_order_type,
        g_order_uom_cd,
        g_original_customer_request_dt_yyyymmdd,
        g_original_promised_ship_dt_yyyymmdd,
        g_parent_order_line_nbr,
        g_payment_terms,
        g_plant_cd,
        g_primary_uom_cd,
        g_promised_ship_dt_yyyymmdd,
        g_scheduled_ship_dt_yyyymmdd,
        g_ship_to_customer_nbr,
        g_ship_to_delivery_days,
        g_shipment_mode,
        g_shipped_qty_primary_uom,
        'gbl' as g_source_system_cd,
        g_unit_cost_company_currency_primary_uom,
        g_unit_price_company_currency_primary_uom,
        g_unit_price_order_currency_primary_uom,
        concat_ws('|', 'gbl', g_plant_cd) as plant_key,
        concat_ws('|', 'gbl', g_item_nbr) as prod_key,
        concat_ws('|', 'gbl', g_item_nbr, g_plant_cd) as prod_plant_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr) as sls_ord_key,
        concat_ws('|', 'gbl', g_order_company_cd, g_order_type, g_order_nbr, g_order_line_nbr, g_delivery_schedule_line_nbr) as sls_ord_sched_key,
        flag_is_blanket
    from sto_join
);