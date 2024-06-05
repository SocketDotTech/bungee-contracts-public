import moment from 'moment';

export const getDateTimeString = () => {
    let formattedDate = moment().format('DD-MMM-YYYY_HH_mm_ss')
    return formattedDate;
}
